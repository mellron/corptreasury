# GetTotalPercentageForTickets Documentation

## Purpose
The `GetTotalPercentageForTickets` function calculates the total percentage of pledged amounts relative to the ticket amounts passed in. It combines tickets passed in explicitly and optionally includes tickets associated with a specific pledgee.

---

## Parameters
| **Parameter**           | **Type**           | **Description**                                     |
|--------------------------|--------------------|-----------------------------------------------------|
| `@Pledgee`              | `VARCHAR(50)`      | The pledgee to filter on. If 'unknown', converts to blank. |
| `@SelectedTickets`      | `VARCHAR(MAX)`     | Comma-separated list of selected ticket IDs.       |
| `@AmountNeeded`         | `DECIMAL(10,2)`    | Additional amount to be added to the total pledged amount. |

---

## Logic Flow
```mermaid
flowchart TD
    Start["Start Function GetTotalPercentageForTickets"] --> ValidateInputs{"Validate Inputs"}
    ValidateInputs -->|@SelectedTickets NULL or Empty| ReturnZero1["Return 0"]
    ValidateInputs -->|@AmountNeeded NULL| ReturnZero2["Return 0"]
    ValidateInputs --> NormalizePledgee{"Is Pledgee 'unknown'?"}
    NormalizePledgee -->|Yes| SetBlank["Set Pledgee to Blank"]
    NormalizePledgee -->|No| ProceedToTickets

    SetBlank --> ProceedToTickets["Insert Tickets into @SelectedTicketsTable"]
    ProceedToTickets --> InsertExplicitTickets["Insert Tickets from @SelectedTickets"]
    InsertExplicitTickets --> CheckPledgee{"Is Pledgee Provided?"}
    CheckPledgee -->|Yes| InsertPledgeeTickets["Insert All Tickets for Pledgee"]
    CheckPledgee -->|No| ProceedToTotals

    InsertPledgeeTickets --> ProceedToTotals["Calculate Totals"]
    ProceedToTotals --> CalculateResults["SUM Amount, Pledged, and Calculate Percentage"]
    CalculateResults --> CheckResult{"Any Results?"}
    CheckResult -->|Yes| ReturnPercentage["Return Calculated Percentage"]
    CheckResult -->|No| ReturnZero3["Return 0"]

    ReturnZero1 --> End["End"]
    ReturnZero2 --> End
    ReturnZero3 --> End
    ReturnPercentage --> End
 
```

---

## Workflow Steps

### 1. Input Validation
   - If `@SelectedTickets` is `NULL` or empty → **Return 0**.
   - If `@AmountNeeded` is `NULL` → **Return 0**.

### 2. Normalize Pledgee
   - If `@Pledgee = 'unknown'`, set it to a blank string.

### 3. Insert Tickets
   - Insert tickets from the `@SelectedTickets` list into `@SelectedTicketsTable` using `dbo.SplitString`.
   - **Check Pledgee**: If a specific pledgee is provided, add all tickets for that pledgee that aren't already included.

### 4. Calculate Totals
   - Join `Tickets` with `@SelectedTicketsTable`.
   - Calculate the following:
     - **Total Amount**: `SUM(Amount)`
     - **Total Pledged**: `SUM(Pledged) + @AmountNeeded`
     - **Percentage**: 
       ```sql
       (SUM(Pledged) + @AmountNeeded) / SUM(Amount) * 100
       ```

### 5. Return Results
   - If calculations produce valid results, return the calculated percentage.
   - Otherwise, return `0`.

---

## Usage Example
```sql
SELECT dbo.GetTotalPercentageForTickets(
    @Pledgee = 'JohnDoe',
    @SelectedTickets = 'TICKET001,TICKET002,TICKET003',
    @AmountNeeded = 1000.00
) AS TotalPercentage;
```

---

## Notes
- **Validation**: Ensures null or invalid inputs return `0`.
- **Dependencies**: Requires the `Tickets` table and `dbo.SplitString` function.
- **Testing Scenarios**:
   - Empty `@SelectedTickets`.
   - Specific `@Pledgee` with no tickets.
   - Valid list of tickets with non-zero `@AmountNeeded`.

---

 
