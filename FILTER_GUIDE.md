# Filter Feature Guide

## What Was Fixed

The "Find Donor" filter dialog now properly applies your selections and shows results from the **government blood bank dataset**.

## How It Works

### 1. Opening the Filter
- Click on **"Find Donor"** card on the main dashboard
- A filter dialog appears with three fields:
  - **City** (optional): e.g., "bengaluru", "mumbai", "delhi"
  - **State** (optional): e.g., "karnataka", "maharashtra", "delhi"
  - **Blood Group** (optional): dropdown with A+, A-, B+, B-, AB+, AB-, O+, O-

### 2. Applying Filters
- Enter your criteria (all fields are optional)
- Click **"Apply"** button
- A loading indicator appears while fetching data

### 3. What Happens After Apply
The system searches in this priority order:

1. **Government Blood Banks** (primary dataset)
   - Searches by city/state if provided
   - Filters by blood group availability (shows only banks with that blood type in stock)
   - Shows available units for each blood group

2. **Fallback to Donor Database** (if no blood banks found)
   - Searches registered donors matching your criteria

### 4. Results Display
The results dialog shows:
- **Blood Bank Name** with hospital icon
- **Location**: City and State
- **Phone Number**
- **Available Blood Groups**: Shows each type with unit count (e.g., "A+(5), B+(3)")
- **Total Units**: Sum of all blood types
- **24x7 Status**: Green clock icon if open 24/7, orange if not

## Example Searches

### Example 1: Blood Group Only
- Blood Group: **B+**
- City: *(leave empty)*
- State: *(leave empty)*
- **Result**: Shows all blood banks nationwide with B+ blood in stock

### Example 2: City + Blood Group
- City: **bengaluru**
- State: **karnataka**
- Blood Group: **B+**
- **Result**: Shows Bengaluru blood banks with B+ blood available

### Example 3: State-Wide Search
- State: **karnataka**
- Blood Group: *(leave empty)*
- **Result**: Shows all Karnataka blood banks with any blood stock

## Technical Details

### Data Source
- Uses the **Government of India Blood Bank Dataset**
- Real blood bank locations with actual contact information
- Live blood unit availability by type

### Blood Group Mapping
The system maps user selections to database columns:
- A+ → `a_positive`
- A- → `a_negative`
- B+ → `b_positive`
- B- → `b_negative`
- AB+ → `ab_positive`
- AB- → `ab_negative`
- O+ → `o_positive`
- O- → `o_negative`

### Filter Logic
```dart
// Only shows blood banks where selected blood type has units > 0
if (bloodGroup == 'B+') {
  return bloodBank.b_positive > 0;
}
```

## Tips for Best Results

1. **Start Broad**: Try searching by state first, then narrow down
2. **Case Insensitive**: City/state search is flexible (bengaluru = Bengaluru = BENGALURU)
3. **Partial Matches**: Backend may support partial city names
4. **No Results?**: Try searching without blood group to see all banks in the area

## What Changed in the Code

### Before
- Filter dialog didn't capture user input properly
- "Apply" button just closed the dialog
- No data was fetched based on filters

### After
- Dialog uses `StatefulBuilder` to track selections
- Returns `true` when Apply is clicked
- Fetches government dataset with filters
- Shows loading indicator during fetch
- Displays filtered results with detailed blood availability
- Clear error messages if no results found

## Troubleshooting

### "No results found"
- Check spelling of city/state
- Try searching state-only (more lenient)
- Remove blood group filter to see all banks

### Loading Takes Too Long
- Backend may be starting up
- Check backend is running at `http://127.0.0.1:5000`
- Network timeout is 30 seconds

### Blood Bank vs Donor Results
- System prioritizes government blood banks
- Falls back to donor database if no banks match
- Blood banks have more reliable availability data

## Backend Requirements

Ensure your Flask backend is running:
```bash
cd backend
python app.py
```

Backend should respond at:
- Health: `http://127.0.0.1:5000/api/health`
- Blood Banks: `http://127.0.0.1:5000/api/blood-banks`

---

**Updated**: November 12, 2025  
**Web Build**: Running at http://127.0.0.1:8080
