# Meteora DLMM SDK — Position Lifecycle Deep Dive

> Source: `dlmm-sdk/ts-client/src/dlmm/`  
> Date: 2025-02-27  
> Purpose: Document edge cases for building a robust LP trading bot

---

## 1. When `removeLiquidity` Returns Multiple Transactions

### The Mechanism: `chunkBinRange`

`removeLiquidity` returns `Promise<Transaction[]>` — **an array, not a single transaction**.

The chunking happens because Solana transactions have size/compute limits. The SDK splits the bin range into chunks of `DEFAULT_BIN_PER_POSITION` = **70 bins** each:

```typescript
// helpers/positions/index.ts — chunkBinRange()
const chunkedBinRange = chunkBinRange(fromBinId, toBinId);
// Each chunk: { lowerBinId, upperBinId } where width ≤ 70 bins
```

**Triggers for multiple transactions:**

1. **Position spans > 70 bins** — A position can span up to `POSITION_MAX_LENGTH` = **1400 bins**. A 1400-bin position = **20 separate transactions** to fully remove.
2. **`shouldClaimAndClose = true` adds more instructions per chunk** — Each chunked transaction includes:
   - `claimFee2` instruction (claims X and Y swap fees for that bin range)
   - Up to 2 `claimReward2` instructions (LM rewards)
   - `closePositionIfEmpty` instruction (only on the last chunk)
   - Token account creation instructions

3. **Each chunk needs its own bin array account references** — Different bin ranges map to different on-chain bin array PDAs.

### Critical Bot Implication

```typescript
// WRONG — will only submit the first transaction
const tx = await dlmm.removeLiquidity({ ... });
await sendAndConfirmTransaction(connection, tx, [user]);

// CORRECT — must iterate ALL transactions sequentially
const txs = await dlmm.removeLiquidity({ ... });
for (const tx of txs) {
  await sendAndConfirmTransaction(connection, tx, [user]);
}
```

⚠️ **Partial withdrawal risk**: If transaction 2 of 3 fails, you have a partially-withdrawn position. The bot MUST handle this — retry remaining transactions or track the partial state.

---

## 2. What Happens When Price Moves Out of Range

### Bin mechanics

- **Active bin** = the bin where the current price sits (`lbPair.activeId`)
- Bins **below** active bin hold only **token Y** (quote token, e.g. USDC)
- Bins **above** active bin hold only **token X** (base token, e.g. SOL)
- The **active bin** can hold both X and Y

### When price moves completely above position range

- All bins in the position are below the active bin
- Position holds **100% token Y** — the position was fully "sold" into Y
- Position is earning **zero fees** (no swaps passing through)
- Liquidity shares are unchanged — you still own the position

### When price moves completely below position range

- All bins in the position are above the active bin  
- Position holds **100% token X** — price dropped, the position "bought" all X
- Position is earning **zero fees**

### SDK Behavior — No Automatic Actions

The SDK does **nothing** when a position goes out of range. Key observations from the code:

1. `processPosition` still calculates `positionXAmount` and `positionYAmount` correctly using the bin supply ratios — but one side will be zero.

2. Fees stop accruing for out-of-range bins because `feeAmountXPerTokenStored` / `feeAmountYPerTokenStored` in those bins are no longer being updated by swaps.

3. You can still `removeLiquidity` on an out-of-range position — the `fromBinId`/`toBinId` are clamped to bins with actual liquidity:

   ```typescript
   // removeLiquidity clips to actual liquidity bounds
   if (fromBinId < lowerBinIdWithLiquidity) {
     fromBinId = lowerBinIdWithLiquidity;
   }
   if (toBinId > upperBinIdWithLiquidity) {
     toBinId = upperBinIdWithLiquidity;
   }
   ```

4. `getPositionLowerUpperBinIdWithLiquidity` filters bins that have non-zero liquidity shares OR unclaimed fees/rewards — it won't skip bins just because they're out of range.

### Bot Detection Strategy

To detect out-of-range:

```typescript
const activeBin = await dlmm.getActiveBin();
const posData = position.positionData;
const isOutOfRange = activeBin.binId < posData.lowerBinId || 
                     activeBin.binId > posData.upperBinId;
const isFullyTokenX = activeBin.binId < posData.lowerBinId; // Price dropped
const isFullyTokenY = activeBin.binId > posData.upperBinId; // Price rose
```

---

## 3. How Fees Are Tracked and Claimed

### Fee Accumulation Model (Per-Bin)

Each bin stores cumulative fee counters:

```typescript
// BinLiquidity type
feeAmountXPerTokenStored: BN;  // Cumulative X fees per liquidity token
feeAmountYPerTokenStored: BN;  // Cumulative Y fees per liquidity token
```

Each position tracks per-bin fee state via `UserFeeInfo`:

```typescript
// Per bin in the position:
feeXPerTokenComplete: BN;  // Last known feeAmountXPerTokenStored
feeXPending: BN;           // Accumulated but unclaimed X fees
feeYPerTokenComplete: BN;  // Last known feeAmountYPerTokenStored
feeYPending: BN;           // Accumulated but unclaimed Y fees
```

### Fee Calculation (in processPosition)

```typescript
// For each bin in the position:
const newFeeX = mulShr(
  posShares[idx].shrn(SCALE_OFFSET),
  bin.feeAmountXPerTokenStored.sub(feeInfo.feeXPerTokenComplete),
  SCALE_OFFSET, Rounding.Down
);
const claimableFeeX = newFeeX.add(feeInfo.feeXPending);
```

The total claimable fees are aggregated into `PositionData.feeX` and `PositionData.feeY`.

### Fee Claiming Methods

| Method | Description |
|--------|-------------|
| `claimSwapFee({ owner, position })` | Claim fees for a single position. Returns `Transaction[]` (chunked by bin range). |
| `claimAllSwapFee({ owner, positions })` | Claim fees for multiple positions. Batched with `MAX_CLAIM_ALL_ALLOWED = 2` per tx. |
| `claimAllRewards({ owner, positions })` | Claims BOTH swap fees AND LM rewards for multiple positions. |

### Fee Owner

Positions can have a separate `feeOwner` field. If `feeOwner` is `PublicKey.default`, fees go to the position `owner`. Otherwise, fees go to the specified `feeOwner` address. This is relevant for operator-managed positions.

### Historical Fee Tracking

The position stores lifetime claimed amounts:

```typescript
totalClaimedFeeXAmount: BN;  // Total X fees ever claimed from this position
totalClaimedFeeYAmount: BN;  // Total Y fees ever claimed from this position
```

### `shouldClaimAndClose` Shortcut

When removing liquidity with `shouldClaimAndClose: true`, the SDK bundles claim + close into the same transaction chunks. The sequence per chunk is:

1. Create token accounts (idempotent)
2. Remove liquidity from bin range
3. Claim swap fees for that bin range
4. Claim LM rewards (up to 2 reward tokens)
5. Call `closePositionIfEmpty` (returns rent SOL to owner)

---

## 4. SDK-Level Validations & Error Conditions

### SDK-Side Validations (before tx submission)

| Check | Location | Error |
|-------|----------|-------|
| No liquidity to remove | `removeLiquidity` | `"No liquidity to remove"` (throws if all bins have zero shares) |
| No fee to claim | `claimSwapFee` | `"No fee to claim"` (throws if `feeX.isZero() && feeY.isZero()`) |
| Discontinuous bin IDs | `processXYAmountDistribution` | `"Discontinuous Bin ID"` |
| Active bin slippage exceeded | `addLiquidityByStrategy` | Uses `maxActiveBinSlippage` (default: 3 bins) — fails on-chain if active bin moved |
| Unknown position account | `wrapPosition` | `"Unknown position account"` — discriminator doesn't match PositionV2 |

### On-Chain Program Errors (from IDL)

Key errors relevant to LP bot operations:

| Code | Name | Meaning for Bot |
|------|------|-----------------|
| 6003 | `ExceededAmountSlippageTolerance` | Deposit amount changed due to active bin movement — retry with fresh data |
| 6004 | `ExceededBinSlippageTolerance` | Active bin moved > `maxActiveBinSlippage` between quote and execution |
| 6007 | `ZeroLiquidity` | Attempting to interact with empty bins |
| 6008 | `InvalidPosition` | Position account is invalid or corrupted |
| 6009 | `BinArrayNotFound` | Required bin array PDA doesn't exist — need to create it first |
| 6012 | `PairInsufficientLiquidity` | Not enough liquidity in pool for the swap |
| 6018 | `MathOverflow` | Arithmetic overflow — usually extreme amounts |
| 6030 | `NonEmptyPosition` | Can't close position that still has liquidity |
| 6031 | `UnauthorizedAccess` | Wrong signer for the operation |
| 6038 | `BinIdOutOfBound` | Bin ID exceeds `MAX_BIN_ID_PER_BIN_STEP` (351,639) |
| 6040 | `InvalidPositionWidth` | Position width exceeds limits |
| 6042 | `PoolDisabled` | Pool has been disabled by admin |
| 6054 | `InvalidStrategyParameters` | Bad strategy config |
| 6055 | `LiquidityLocked` | Position is locked (has `lockReleasePoint`) |

### Error Handling Pattern in SDK

The SDK provides `DLMMError` class that parses Anchor errors from transaction logs:

```typescript
// error.ts
const anchorError = AnchorError.parse(logs);
// Maps to { errorCode, errorName, errorMessage }
```

---

## 5. Position Object — Complete Field Reference

### `PositionData` (returned by `getPositionsByUserAndLbPair`, `processPosition`)

```typescript
interface PositionData {
  // === Amounts ===
  totalXAmount: string;           // Total token X in position (lamports, as string)
  totalYAmount: string;           // Total token Y in position (lamports, as string)
  
  // === Bin Range ===
  lowerBinId: number;             // Lowest bin ID in position
  upperBinId: number;             // Highest bin ID in position
  
  // === Per-Bin Data ===
  positionBinData: PositionBinData[];  // Array of per-bin breakdown
  
  // === Claimable Fees (aggregated across all bins) ===
  feeX: BN;                       // Total claimable X fee right now
  feeY: BN;                       // Total claimable Y fee right now
  
  // === Claimable LM Rewards ===
  rewardOne: BN;                   // Claimable reward token 1
  rewardTwo: BN;                   // Claimable reward token 2
  
  // === Historical ===
  totalClaimedFeeXAmount: BN;     // Lifetime claimed X fees
  totalClaimedFeeYAmount: BN;     // Lifetime claimed Y fees
  lastUpdatedAt: BN;              // Timestamp of last position update
  
  // === Transfer Fee Adjusted (Token2022) ===
  feeXExcludeTransferFee: BN;     // X fee minus Token2022 transfer fees
  feeYExcludeTransferFee: BN;     // Y fee minus Token2022 transfer fees
  rewardOneExcludeTransferFee: BN;
  rewardTwoExcludeTransferFee: BN;
  totalXAmountExcludeTransferFee: BN;
  totalYAmountExcludeTransferFee: BN;
  
  // === Ownership ===
  feeOwner: PublicKey;             // Who receives fees (default = owner)
  owner: PublicKey;                // Position owner
}
```

### `PositionBinData` (per-bin within position)

```typescript
interface PositionBinData {
  binId: number;                   // Bin ID
  price: string;                   // Price per lamport at this bin
  pricePerToken: string;           // Human-readable price per token
  
  // Bin-level totals (all LPs combined)
  binXAmount: string;              // Total X in this bin
  binYAmount: string;              // Total Y in this bin
  binLiquidity: string;            // Total liquidity supply in bin
  
  // This position's share
  positionLiquidity: string;       // This position's liquidity share
  positionXAmount: string;         // This position's X amount
  positionYAmount: string;         // This position's Y amount
  
  // This position's unclaimed fees/rewards in this bin
  positionFeeXAmount: string;      // Claimable X fee from this bin
  positionFeeYAmount: string;      // Claimable Y fee from this bin
  positionRewardAmount: string[];  // [reward1, reward2] claimable from this bin
}
```

### `IPosition` (low-level wrapper, from on-chain account)

```typescript
interface IPosition {
  address(): PublicKey;
  lowerBinId(): BN;
  upperBinId(): BN;
  liquidityShares(): BN[];         // Array of shares per bin
  rewardInfos(): UserRewardInfo[]; // Per-bin reward tracking
  feeInfos(): UserFeeInfo[];       // Per-bin fee tracking
  lastUpdatedAt(): BN;
  lbPair(): PublicKey;
  totalClaimedFeeXAmount(): BN;
  totalClaimedFeeYAmount(): BN;
  totalClaimedRewards(): BN[];
  operator(): PublicKey;
  lockReleasePoint(): BN;          // 0 = unlocked, >0 = locked until this slot/timestamp
  feeOwner(): PublicKey;
  owner(): PublicKey;
  version(): PositionVersion;      // Always V2 now
  width(): BN;                     // upperBinId - lowerBinId + 1
}
```

### `LbPosition` (the return type from position queries)

```typescript
interface LbPosition {
  publicKey: PublicKey;            // On-chain address of position account
  positionData: PositionData;      // Processed data (see above)
  version: PositionVersion;        // V1 or V2
}
```

---

## 6. Strategy Types

### `StrategyType` Enum

```typescript
enum StrategyType {
  Spot = 0,    // Uniform distribution across bins
  Curve = 1,   // Bell curve — concentrated around active bin
  BidAsk = 2,  // Inverse bell — more at edges, less at center
}
```

### Strategy Mapping (SDK → On-Chain)

The SDK always sends `ImBalanced` variants to the program, using the `parameteres[0]` byte to signal side preference:

| SDK Type | On-Chain Type | parameteres[0] | Behavior |
|----------|---------------|----------------|----------|
| `Spot` | `spotImBalanced` | 0 (both sides) or 1 (favor X/ask) | Equal weight per bin |
| `Curve` | `curveImBalanced` | 0 or 1 | Weights peak at active bin, taper to edges |
| `BidAsk` | `bidAskImBalanced` | 0 or 1 | Weights low at active bin, high at edges |

### One-Sided Deposits

One-sided deposits work by setting one amount to zero:

```typescript
// X-only deposit (ask side — bins above active bin)
const createPositionTx = await dlmm.initializePositionAndAddLiquidityByStrategy({
  totalXAmount: new BN(1_000_000_000), // 1 SOL
  totalYAmount: new BN(0),              // No Y token
  strategy: {
    minBinId: activeBin.binId,          // Start at active bin
    maxBinId: activeBin.binId + 20,     // 20 bins above
    strategyType: StrategyType.Spot,
    singleSidedX: true,                 // Signals X-side preference
  },
});
```

The `singleSidedX` flag sets `parameteres[0] = 1`, telling the on-chain program to favor the X/ask side.

When `amountY.isZero()` (single-sided X), the strategy code in `toAmountsBothSideByStrategy` takes a special code path that distributes liquidity starting from the active bin upward, instead of splitting around the active bin.

---

## 7. Bin IDs and Active Bin Movement

### Bin ID Mechanics

- Each bin represents a **discrete price point**: `price = (1 + binStep/10000) ^ (binId - 0)`
- `binStep` is the pool's configured step size (e.g., 1 = 0.01%, 100 = 1% per bin)
- Bin IDs can be negative (very low prices) or positive  
- Max bin ID per step: `MAX_BIN_ID_PER_BIN_STEP` = **351,639**

### Bin Array Organization

- Bins are grouped into **bin arrays** of `MAX_BIN_PER_ARRAY` = **70 bins** each
- `binArrayIndex = floor(binId / 70)` (with sign handling)
- Each bin array is a separate on-chain PDA account

### What Happens When Active Bin Moves Far

1. **Active bin slippage protection**: `addLiquidityByStrategy` defaults to `MAX_ACTIVE_BIN_SLIPPAGE = 3`. If the active bin moved more than 3 bins between your quote and transaction execution, the on-chain program rejects with `ExceededBinSlippageTolerance` (error 6004). The bot must re-fetch and retry.

2. **Position width is fixed at creation**: A position's `lowerBinId` and `upperBinId` never change. The active bin moves independently. If the active bin moves far from the position, the position simply becomes out-of-range (see section 2).

3. **Impermanent loss**: As the active bin moves through your position's range:
   - Moving up (price increase): bins convert from holding X to holding Y — you sell X for Y
   - Moving down (price decrease): bins convert from holding Y to holding X — you buy X with Y
   - Once the active bin exits your range entirely, IL crystallizes

4. **Position can be expanded**: `increasePositionLength` can add bins to one or both sides, up to `POSITION_MAX_LENGTH = 1400`.

---

## Key Constants Summary

| Constant | Value | Meaning |
|----------|-------|---------|
| `DEFAULT_BIN_PER_POSITION` | 70 | Default bins per position; chunking unit for transactions |
| `POSITION_MAX_LENGTH` | 1400 | Maximum bins a single position can span |
| `MAX_BIN_PER_ARRAY` | 70 | Bins per on-chain bin array account |
| `MAX_CLAIM_ALL_ALLOWED` | 2 | Max claim operations bundled per transaction |
| `MAX_ACTIVE_BIN_SLIPPAGE` | 3 | Default max bin movement tolerance for deposits |
| `MAX_BIN_ID_PER_BIN_STEP` | 351,639 | Max allowed bin ID |
| `BIN_ARRAY_FEE` | 0.0714 SOL | Rent cost for creating a new bin array |
| `POSITION_FEE` | 0.0574 SOL | Rent cost for creating a position |

---

## Bot Implementation Checklist

- [ ] **Always iterate `Transaction[]`** from `removeLiquidity` — never assume single tx
- [ ] **Handle partial withdrawal** — if tx N of M fails, position is in partial state  
- [ ] **Check out-of-range** before removing — compare `activeBin.binId` vs position range
- [ ] **Claim fees before closing** — use `shouldClaimAndClose: true` or claim separately
- [ ] **Handle slippage errors** — catch error 6003/6004, re-fetch active bin, retry
- [ ] **Track `feeX`/`feeY`** for P&L — these are the actual earned trading fees
- [ ] **Use `totalClaimedFeeXAmount`/`totalClaimedFeeYAmount`** for lifetime P&L tracking
- [ ] **Handle `PoolDisabled` (6042)** — pool can be disabled by admin at any time
- [ ] **Handle `LiquidityLocked` (6055)** — some positions have lock periods
- [ ] **Create bin arrays before adding liquidity** — `initializePositionAndAddLiquidityByStrategy` does this automatically, but manual flows may not
- [ ] **Budget for rent costs** — each position costs ~0.057 SOL, each new bin array ~0.071 SOL
