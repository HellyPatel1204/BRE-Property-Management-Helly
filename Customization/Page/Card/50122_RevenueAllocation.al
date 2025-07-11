page 50122 "Revenue Allocation Card"
{
    PageType = Card;
    SourceTable = "Revenue Allocation Details";
    ApplicationArea = All;
    Caption = 'Revenue Allocation Details';
    //  UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Group)
            {
                Caption = 'Revenue Allocation Details';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        if xRec."No." <> Rec."No." then
                            ClearSubgridData();
                    end;
                }
                field(Month; Rec.Month)
                {
                    ApplicationArea = All;
                }
                field("Financial Year"; Rec."Financial Year")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group("Revenue Allocation Report Details")
            {
                Caption = 'Revenue Allocation Report Details';
                part("Revenue Allocation Details"; "Revenue Allocation SubGrid")
                {
                    SubPageLink = "Header No." = field("No.");
                }
            }
            group("Total Calculations")
            {
                Caption = 'Total Calculations(Rent)';
                field(TotalContractAmount; TotalContractAmount)
                {
                    Caption = 'Total Contract Amount';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(TotalAnnualAmount; TotalAnnualAmount)
                {
                    Caption = 'Total Annual Amount';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(TotalFinalAnnualAmount; TotalFinalAnnualAmount)
                {
                    Caption = 'Total Final Annual Amount';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(TotalValue; TotalValue)
                {
                    Caption = 'Total Value';
                    Editable = false;
                    ApplicationArea = All;
                }
            }

            group("Revenue Recognition Item")
            {
                Caption = 'Revenue Item Details';
                part("Revenue Recognition Item Details"; "Revenue Recognition Item Sub")
                {
                    SubPageLink = "RR_No." = field("No.");
                }
            }

            group("Revenue Recognition Detail")
            {
                Caption = 'Revenue Recognition Details';
                part("Revenue Recognition Details"; "Revenue Recognition Detail Sub")
                {
                    SubPageLink = "RR_No." = field("No.");
                }
            }
            group(" ")
            {
                Caption = 'Total Calculations(Other Charges)';
                field("Total Amount"; totalamounts)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount';
                    Editable = false;
                }

                field("Total Annual Amount"; TotalAnnualAmounts)
                {
                    Caption = 'Total Annual Amount';
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Total Final Annual Amount"; TotalFinalAnnualAmounts)
                {
                    Caption = 'Total Final Annual Amount';
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Total Contract Amount"; totalcontractAmounts)
                {
                    ApplicationArea = All;
                    Caption = 'Total Contract Amount';
                    Editable = false;
                }
            }
            group("Final Amount")
            {
                Caption = 'Final Amount';

                field(TotalAnnualAmounts; TotalAnnualAmount)
                {
                    Caption = 'Total Annual Amount';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(TotalFinalAnnualAmounts; TotalFinalAnnualAmount)
                {
                    Caption = 'Total Final Annual Amount';
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Total Amounts"; totalcombineamounts)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount';
                    Editable = false;
                }
                field("Total Contract Amounts"; totalcombinecontractAmounts)
                {
                    ApplicationArea = All;
                    Caption = 'Total Contract Amount';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FilterSubgrid)
            {
                Caption = 'Revenue Allocation-Rent';
                trigger OnAction()
                var
                    companydata: Record "testData";
                begin
                    if companydata.FindSet() then begin
                        if companydata."Revenue Methods" = companydata."Revenue Methods"::"Per Day Rent" then begin
                            FetchContracts();
                            CalculateTotals();
                        end else begin
                            FetchContractss();
                            CalculateTotals();
                        end;
                    end;
                end;
            }

            action(RevenueAllocation)
            {
                ApplicationArea = All;
                Caption = 'Revenue Allocation Approval';
                Image = PostDocument;
                Enabled = Rec.Status = Rec.Status::Pending;

                trigger OnAction()
                var
                    Approvalrevenueallocation: Record "Revenue Allocation Approval";
                    revenueallocation: Record "Revenue Allocation Details";
                begin
                    // Validate required fields
                    if Rec."No." = 0 then
                        Error('No must be specified');

                    Approvalrevenueallocation.SetRange("ID", Rec."No.");

                    if Approvalrevenueallocation.FindSet() then begin
                        // Modify existing approval record
                        Approvalrevenueallocation."ID" := Rec."No.";
                        Approvalrevenueallocation."Month" := Rec."Month";
                        Approvalrevenueallocation."Financial Year" := Rec."Financial Year";
                        Approvalrevenueallocation."Status" := Rec."Status";
                        Approvalrevenueallocation.Modify();
                        Message('Approval Request Modified successfully!');
                    end else begin
                        // Insert new approval record
                        Approvalrevenueallocation.Init();
                        Approvalrevenueallocation."ID" := Rec."No.";
                        Approvalrevenueallocation."Financial Year" := Rec."Financial Year";
                        Approvalrevenueallocation."Month" := Rec."Month";
                        Approvalrevenueallocation."Status" := Rec."Status";
                        Approvalrevenueallocation.Insert();
                        Message('Approval Request Sent successfully!');
                    end;
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearSubgridData();
    end;

    trigger OnAfterGetRecord()
    begin
        CalculateTotals();
        CurrPage."Revenue Recognition Item Details".Page.SetRIID(Rec."No.");
        CurrPage."Revenue Recognition Details".Page.SetRIID(Rec."No.");
    end;


    //---------------Calculate Totals--------------//
    var
        TotalContractAmount: Decimal;
        TotalAnnualAmount: Decimal;
        TotalFinalAnnualAmount: Decimal;
        TotalValue: Decimal;


    procedure CalculateTotals()
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        SuspensionRec: Record SuspendReasonTable;
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
    begin
        // Reset totals
        TotalContractAmount := 0;
        TotalAnnualAmount := 0;
        TotalFinalAnnualAmount := 0;
        TotalValue := 0;

        // Get first and last day of selected month
        SelectedMonthStart := DMY2Date(1, Rec.Month, Rec."Financial Year");
        SelectedMonthEnd := CALCDATE('<CM>', SelectedMonthStart);

        // Filter records for the current header
        FilteredContractRec.Reset();
        FilteredContractRec.SetRange("Header No.", Rec."No.");

        // Calculate totals
        if FilteredContractRec.FindSet() then begin
            repeat
                // Check if the contract is suspended during the selected month
                SuspensionRec.Reset();
                SuspensionRec.SetRange("Contract ID", FilteredContractRec."Contract Id");
                SuspensionRec.SetFilter(DateEffective, '..%1', SelectedMonthEnd);
                SuspensionRec.SetFilter(SuspensionEndDate, '%1..', SelectedMonthStart);

                // Only add to totals if the contract is NOT suspended during the selected month
                if not SuspensionRec.FindFirst() then begin
                    TotalContractAmount += FilteredContractRec."Contract Amount";
                    TotalAnnualAmount += FilteredContractRec."Annual Amount";
                    TotalFinalAnnualAmount += FilteredContractRec."Final Annual Amount";
                    TotalValue += FilteredContractRec."Total Value";
                end;
            until FilteredContractRec.Next() = 0;
        end;
        CurrPage.Update(false);
    end;

    procedure CalculateDaysInSelectedMonth(
        ContractStartDate: Date;
        ContractEndDate: Date;
        MultiYearStartDate: Date;
        MultiYearEndDate: Date;
        SelectedMonth: Integer;
        SelectedYear: Integer): Integer
    var
        StartDate: Date;
        EndDate: Date;
        MonthStartDate: Date;
        MonthEndDate: Date;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
    begin
        // Get first day of selected month (without +1, assuming SelectedMonth is correct)
        MonthStartDate := DMY2Date(1, SelectedMonth, SelectedYear);
        // Get last day of selected month
        MonthEndDate := CALCDATE('<+1M-1D>', MonthStartDate);

        // Return 0 if multi-year period is completely outside selected month
        if (MultiYearStartDate > MonthEndDate) or (MultiYearEndDate < MonthStartDate) then
            exit(0);

        // Determine effective start date for the month
        // Use the latest of: MonthStart, MultiYearStart, ContractStart
        EffectiveStartDate := MonthStartDate;
        if MultiYearStartDate > EffectiveStartDate then
            EffectiveStartDate := MultiYearStartDate;
        if ContractStartDate > EffectiveStartDate then
            EffectiveStartDate := ContractStartDate;

        // Determine effective end date for the month  
        // Use the earliest of: MonthEnd, MultiYearEnd, ContractEnd
        EffectiveEndDate := MonthEndDate;
        if MultiYearEndDate < EffectiveEndDate then
            EffectiveEndDate := MultiYearEndDate;
        if ContractEndDate < EffectiveEndDate then
            EffectiveEndDate := ContractEndDate;

        // Ensure we don't have invalid date range
        if EffectiveStartDate > EffectiveEndDate then
            exit(0);

        // Calculate inclusive number of days
        exit(EffectiveEndDate - EffectiveStartDate + 1);
    end;

    //---------------Clear Subgrid Data--------------//
    procedure ClearSubgridData()
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        revenueitem: Record "Revenue Recognition Item";
    begin
        FilteredContractRec.Reset();
        FilteredContractRec.SetRange("Header No.", Rec."No.");
        FilteredContractRec.DeleteAll();
        revenueitem.Reset();
        revenueitem.SetRange("RR_No.", Rec."No.");
        revenueitem.DeleteAll();
    end;


    //---------------Get Next LineNo--------------//
    procedure GetNextLineNo(): Integer
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        LastLineNo: Integer;
    begin
        FilteredContractRec.Reset();
        FilteredContractRec.SetRange("Header No.", Rec."No.");
        if FilteredContractRec.FindLast() then
            LastLineNo := FilteredContractRec."Line No."
        else
            LastLineNo := 0;
        exit(LastLineNo + 1);
    end;


    //---------------Should Keep Entry--------------//
    procedure ShouldKeepEntry(StartDate: Date; EndDate: Date): Boolean
    var
        CheckDate: Date;
        LastDayOfMonth: Date;
        FirstDayOfMonth: Date;
    begin
        // Get first day of selected month
        FirstDayOfMonth := DMY2Date(1, Rec.Month, Rec."Financial Year");

        // Get last day of selected month
        LastDayOfMonth := CALCDATE('<+1M-1D>', FirstDayOfMonth);

        // Check if selected month's date range overlaps with the given date range
        // A period overlaps if:
        if (StartDate <= LastDayOfMonth) and (EndDate >= FirstDayOfMonth) then
            exit(true);

        exit(false);
    end;


    //---------------Insert Allocation Line--------------//

    // Helper procedure to insert allocation line

    // Modified InsertAllocationLine procedure with grace period date check
    // Modified InsertAllocationLine procedure with grace period date check
    procedure InsertAllocationLine(
     ContractRec: Record "Tenancy Contract";
     MultiYearStartDate: Date;
     MultiYearEndDate: Date;
     NoOfDays: Integer;
     PerDayRent: Decimal;
     TotalAnnualAmount: Decimal;
     OwnerShareAmount: Decimal;
     TerminationDate: Date;
     LineNo: Integer;
     MonthNo: Integer;
     FinancialYear: Integer)
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        SuspensionRec: Record SuspendReasonTable;
        CalculatedDays: Integer;
        NewLineNo: Integer;
        PerDayRentWithoutGracePeriod: Decimal;
        PerDayRentWithGracePeriod: Decimal;
        TotalContractDays: Integer;
        TotalContractDaysWithGrace: Integer;
        DifferencePerDayRent: Decimal;
        GracePeriodAdjustmentValue: Decimal;
        GridAnnualAmount: Decimal;
        // New variables for grace period date check
        GraceStartDate: Date;
        GraceEndDate: Date;
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
        ShouldInsertGraceLine: Boolean;
        AdjustedStartDate: Date; // 🔹 new
        AdjustedEndDate: Date;   // 🔹 new
        SuspensionStartDateInMonth: Date; // 🔹 ADDED   
    begin
        // Check if entry should be kept based on date range
        if not ShouldKeepEntry(MultiYearStartDate, MultiYearEndDate) then
            exit;

        // Calculate selected month date range
        SelectedMonthStart := DMY2Date(1, MonthNo, FinancialYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Calculate grace period dates
        GraceStartDate := ContractRec."Grace Start Date";
        GraceEndDate := ContractRec."Grace End Date";

        // Check if grace period falls within selected month
        // Grace period should be inserted only if grace start date and grace end date 
        // overlap with the selected month
        ShouldInsertGraceLine := (ContractRec."Grace Period" > 0) and
                                (GraceStartDate <> 0D) and (GraceEndDate <> 0D) and
                                (GraceStartDate <= SelectedMonthEnd) and
                                (GraceEndDate >= SelectedMonthStart);

        // Get new line number
        NewLineNo := GetNextLineNo();

        // 🔹 NEW: Calculate AdjustedStartDate & AdjustedEndDate
        AdjustedStartDate := MultiYearStartDate;
        if AdjustedStartDate < SelectedMonthStart then
            AdjustedStartDate := SelectedMonthStart;

        AdjustedEndDate := MultiYearEndDate;
        if AdjustedEndDate > SelectedMonthEnd then
            AdjustedEndDate := SelectedMonthEnd;

        if (TerminationDate <> 0D) and (AdjustedEndDate > TerminationDate) then
            AdjustedEndDate := TerminationDate;

        // 🔹 Adjust for Suspension Start
        SuspensionRec.Reset();
        SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
        if SuspensionRec.FindFirst() then begin
            if (SuspensionRec.DateEffective <> 0D) and
               (SuspensionRec.DateEffective >= SelectedMonthStart) and
               (SuspensionRec.DateEffective <= SelectedMonthEnd) then begin
                SuspensionStartDateInMonth := SuspensionRec.DateEffective;
                AdjustedEndDate := SuspensionRec.DateEffective - 1; // 🔹 ADDED
            end;
        end;

        if (AdjustedStartDate <= AdjustedEndDate) then
            CalculatedDays := AdjustedEndDate - AdjustedStartDate + 1
        else
            CalculatedDays := 0;


        // // Calculate the actual number of days for the selected month
        // CalculatedDays := CalculateDaysInSelectedMonth(
        //     ContractRec."Contract Start Date",
        //     ContractRec."Contract End Date",
        //     MultiYearStartDate,
        //     MultiYearEndDate,
        //     MonthNo,
        //     FinancialYear
        // );

        // Get the days in the specific grid record's date range
        TotalContractDays := MultiYearEndDate - MultiYearStartDate + 1;

        // Calculate Total Contract Days (with grace period)
        TotalContractDaysWithGrace := TotalContractDays + ContractRec."Grace Period";

        // Use the annual amount from the grid record instead of the main contract
        GridAnnualAmount := TotalAnnualAmount;

        // Calculate Per Day Rent without Grace Period (using grid's annual amount)
        PerDayRentWithoutGracePeriod := Round(GridAnnualAmount / TotalContractDays);

        // Calculate Per Day Rent with Grace Period (using grid's annual amount)
        PerDayRentWithGracePeriod := Round(GridAnnualAmount / TotalContractDaysWithGrace);

        // Calculate the difference per day
        DifferencePerDayRent := PerDayRentWithoutGracePeriod - PerDayRentWithGracePeriod;

        // Calculate total adjustment value for the month
        GracePeriodAdjustmentValue := DifferencePerDayRent * CalculatedDays;

        // -----------------------------------------------
        // Insert main allocation line (without grace period adjustment)
        // -----------------------------------------------
        FilteredContractRec.Init();
        FilteredContractRec."Line No." := NewLineNo;
        FilteredContractRec."Header No." := Rec."No.";
        FilteredContractRec."Property Name" := ContractRec."Property Name";
        FilteredContractRec."Contract Id" := ContractRec."Contract ID";
        FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
        FilteredContractRec."Customer Name" := ContractRec."Customer Name";
        FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
        FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
        FilteredContractRec."Grace Days" := ContractRec."Grace Period";
        FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
        FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";
        FilteredContractRec.Description := 'Regular';

        if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
            FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
        else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
            FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
        else
            FilteredContractRec."Single Unit Names" := '';

        // Add Termination Date
        if TerminationDate = 0D then
            FilteredContractRec."Termination Date" := 0D
        else
            FilteredContractRec."Termination Date" := TerminationDate;

        SuspensionRec.Reset();
        SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
        if SuspensionRec.FindFirst() then begin
            FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
            FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
        end;

        FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
        FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
        FilteredContractRec."No Of Days" := CalculatedDays;
        FilteredContractRec."Per Day Rent" := Round(PerDayRent); // Use the per day rent passed from the grid
        FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount"; // Use grid's annual amount
        FilteredContractRec."Annual Amount" := GridAnnualAmount;
        FilteredContractRec."Total Value" := CalculatedDays * FilteredContractRec."Per Day Rent";
        FilteredContractRec."Owner Share" := CalculatedDays * FilteredContractRec."Per Day Rent";
        FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
        FilteredContractRec."Posting Month" := MonthNo;
        FilteredContractRec."Posting Year" := FinancialYear;
        FilteredContractRec."Posting Period" := Format(FilteredContractRec."Posting Month") +
            ' ' + Format(FilteredContractRec."Posting Year") + ' ' + '-' + ' ' +
            Format(FilteredContractRec."Posting Month") + ' ' + Format(FilteredContractRec."Posting Year");
        FilteredContractRec."Owner Name" := ContractRec."Owner's Name";
        FilteredContractRec.Insert();

        // -----------------------------------------------
        // Insert grace period adjustment line (negative allocation)
        // Only if grace period dates fall within selected month
        // -----------------------------------------------
        if ShouldInsertGraceLine then begin
            NewLineNo := GetNextLineNo();

            FilteredContractRec.Init();
            FilteredContractRec."Line No." := NewLineNo;
            FilteredContractRec."Header No." := Rec."No.";
            FilteredContractRec."Property Name" := ContractRec."Property Name";
            FilteredContractRec."Contract Id" := ContractRec."Contract ID";
            FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
            FilteredContractRec."Customer Name" := ContractRec."Customer Name";
            FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
            FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
            FilteredContractRec."Grace Days" := ContractRec."Grace Period";
            FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
            FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";
            FilteredContractRec.Description := 'Grace Period';

            if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
            else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
            else
                FilteredContractRec."Single Unit Names" := '';

            // Add Termination Date
            if TerminationDate = 0D then
                FilteredContractRec."Termination Date" := 0D
            else
                FilteredContractRec."Termination Date" := TerminationDate;

            if SuspensionRec.FindFirst() then begin
                FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
                FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
            end;

            FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
            FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
            FilteredContractRec."No Of Days" := CalculatedDays;
            FilteredContractRec."Per Day Rent" := -DifferencePerDayRent; // Negative value
            FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount"; // Use grid's annual amount
            FilteredContractRec."Annual Amount" := GridAnnualAmount;
            FilteredContractRec."Total Value" := -GracePeriodAdjustmentValue; // Negative adjustment
            FilteredContractRec."Owner Share" := -GracePeriodAdjustmentValue; // Negative adjustment
            FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
            FilteredContractRec."Posting Month" := MonthNo;
            FilteredContractRec."Posting Year" := FinancialYear;
            FilteredContractRec."Posting Period" := Format(FilteredContractRec."Posting Month") +
                ' ' + Format(FilteredContractRec."Posting Year") + ' ' + '-' + ' ' +
                Format(FilteredContractRec."Posting Month") + ' ' + Format(FilteredContractRec."Posting Year");
            FilteredContractRec."Owner Name" := ContractRec."Owner's Name";
            // Add a description to indicate this is a grace period adjustment
            // FilteredContractRec."Description" := 'Grace Period Adjustment';
            FilteredContractRec.Insert();
        end;
    end;


    // Add this new helper procedure to handle missed revenue allocations
    procedure HandleMissedAllocation(
     ContractRec: Record "Tenancy Contract";
     MonthNo: Integer;
     FinancialYear: Integer)
    var
        PreviousMonthNo: Integer;
        PreviousYearNo: Integer;
        PreviousMonthStart: Date;
        PreviousMonthEnd: Date;
        CurrentMonthStart: Date;
        CurrentMonthEnd: Date;
        ContractStartDate: Date;
        MissedDays: Integer;
        SingleUnitRent: Record "TC Single Unit Rent SubPage";
        MultiUnitRent: Record "TC Single LumAnnualAmnt SP";
        MergedSingleRent: Record "TC Merge SameSqure SubPage";
        MergedMultiRent: Record "TC Merge DifferentSq SubPage";
        SpecialRent: Record "TC Merge LumAnnualAmount SP";
        FinalCalculationRec: Record "Final Calculation";
        TerminationDate: Date;
        LineNo: Integer;
    begin
        // Calculate previous month and year
        if MonthNo = 1 then begin
            PreviousMonthNo := 12;
            PreviousYearNo := FinancialYear - 1;
        end else begin
            PreviousMonthNo := MonthNo - 1;
            PreviousYearNo := FinancialYear;
        end;

        // Calculate date ranges
        PreviousMonthStart := DMY2Date(1, PreviousMonthNo, PreviousYearNo);
        PreviousMonthEnd := CALCDATE('<CM>', PreviousMonthStart);
        CurrentMonthStart := DMY2Date(1, MonthNo, FinancialYear);
        CurrentMonthEnd := CALCDATE('<CM>', CurrentMonthStart);
        ContractStartDate := ContractRec."Contract Start Date";

        // Check if contract started in previous month
        if (ContractStartDate >= PreviousMonthStart) and (ContractStartDate <= PreviousMonthEnd) then begin
            // Contract started in previous month, so we need to allocate missed days
            MissedDays := PreviousMonthEnd - ContractStartDate + 1;

            // Retrieve Termination Date from Final Calculation
            FinalCalculationRec.Reset();
            FinalCalculationRec.SetRange("Contract ID", ContractRec."Contract ID");
            if FinalCalculationRec.FindFirst() then
                TerminationDate := FinalCalculationRec."Termination Date"
            else
                TerminationDate := 0D;

            // Process each rent type for missed allocation
            // Check Single Unit Rent grid
            SingleUnitRent.Reset();
            SingleUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
            if SingleUnitRent.FindSet() then begin
                repeat
                    if (SingleUnitRent."Start Date" <= PreviousMonthEnd) and (SingleUnitRent."End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLine(
                            ContractRec,
                            SingleUnitRent."Start Date",
                            SingleUnitRent."End Date",
                            SingleUnitRent."Number of Days",
                            SingleUnitRent."Per Day Rent",
                            SingleUnitRent."Final Annual Amount",
                            SingleUnitRent."Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until SingleUnitRent.Next() = 0;
            end;

            // Check Multi Unit Rent grid
            MultiUnitRent.Reset();
            MultiUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
            if MultiUnitRent.FindSet() then begin
                repeat
                    if (MultiUnitRent."SL_Start Date" <= PreviousMonthEnd) and (MultiUnitRent."SL_End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLine(
                            ContractRec,
                            MultiUnitRent."SL_Start Date",
                            MultiUnitRent."SL_End Date",
                            MultiUnitRent."SL_Number of Days",
                            MultiUnitRent."SL_Per Day Rent",
                            MultiUnitRent."SL_Final Annual Amount",
                            MultiUnitRent."SL_Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until MultiUnitRent.Next() = 0;
            end;

            // Check Merged Single Rent grid
            MergedSingleRent.Reset();
            MergedSingleRent.SetRange("Contract ID", ContractRec."Contract ID");
            if MergedSingleRent.FindSet() then begin
                repeat
                    if (MergedSingleRent."MS_Start Date" <= PreviousMonthEnd) and (MergedSingleRent."MS_End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLine(
                            ContractRec,
                            MergedSingleRent."MS_Start Date",
                            MergedSingleRent."MS_End Date",
                            MergedSingleRent."MS_Number of Days",
                            MergedSingleRent."MS_Per Day Rent",
                            MergedSingleRent."MS_Final Annual Amount",
                            MergedSingleRent."MS_Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until MergedSingleRent.Next() = 0;
            end;

            // Check Merged Multi Rent grid
            MergedMultiRent.Reset();
            MergedMultiRent.SetRange("Contract ID", ContractRec."Contract ID");
            if MergedMultiRent.FindSet() then begin
                repeat
                    if (MergedMultiRent."MD_Start Date" <= PreviousMonthEnd) and (MergedMultiRent."MD_End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLine(
                            ContractRec,
                            MergedMultiRent."MD_Start Date",
                            MergedMultiRent."MD_End Date",
                            MergedMultiRent."MD_Number of Days",
                            MergedMultiRent."MD_Per Day Rent",
                            MergedMultiRent."MD_Final Annual Amount",
                            MergedMultiRent."MD_Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until MergedMultiRent.Next() = 0;
            end;

            // Check Special Rent grid
            SpecialRent.Reset();
            SpecialRent.SetRange("Contract ID", ContractRec."Contract ID");
            if SpecialRent.FindSet() then begin
                repeat
                    if (SpecialRent."ML_Start Date" <= PreviousMonthEnd) and (SpecialRent."ML_End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLine(
                            ContractRec,
                            SpecialRent."ML_Start Date",
                            SpecialRent."ML_End Date",
                            SpecialRent."ML_Number of Days",
                            SpecialRent."ML_Per Day Rent",
                            SpecialRent."ML_Final Annual Amount",
                            SpecialRent."ML_Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until SpecialRent.Next() = 0;
            end;
        end;
    end;

    // Helper procedure to insert missed allocation lines
    // Helper procedure to insert missed allocation lines
    procedure InsertMissedAllocationLine(
     ContractRec: Record "Tenancy Contract";
     MultiYearStartDate: Date;
     MultiYearEndDate: Date;
     NoOfDays: Integer;
     PerDayRent: Decimal;
     TotalAnnualAmount: Decimal;
     OwnerShareAmount: Decimal;
     TerminationDate: Date;
     LineNo: Integer;
     PreviousMonthNo: Integer;
     PreviousYearNo: Integer;
     ContractStartDate: Date;
     PreviousMonthEnd: Date)
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        SuspensionRec: Record SuspendReasonTable;
        CalculatedDays: Integer;
        NewLineNo: Integer;
        PerDayRentWithoutGracePeriod: Decimal;
        PerDayRentWithGracePeriod: Decimal;
        TotalContractDays: Integer;
        TotalContractDaysWithGrace: Integer;
        DifferencePerDayRent: Decimal;
        GracePeriodAdjustmentValue: Decimal;
        GridAnnualAmount: Decimal;
        MissedDays: Integer;
        // New variables for grace period date check
        GraceStartDate: Date;
        GraceEndDate: Date;
        ShouldInsertGraceLine: Boolean;
    begin
        // Calculate missed days
        MissedDays := PreviousMonthEnd - ContractStartDate + 1;

        // Get new line number
        NewLineNo := GetNextLineNo();

        // Use the annual amount from the grid record instead of the main contract
        GridAnnualAmount := TotalAnnualAmount;

        // Calculate Total Contract Days
        TotalContractDays := MultiYearEndDate - MultiYearStartDate + 1;

        // Calculate Total Contract Days (with grace period)
        TotalContractDaysWithGrace := TotalContractDays + ContractRec."Grace Period";

        // Calculate Per Day Rent without Grace Period (using grid's annual amount)
        PerDayRentWithoutGracePeriod := Round(GridAnnualAmount / TotalContractDays);

        // Calculate Per Day Rent with Grace Period (using grid's annual amount)
        PerDayRentWithGracePeriod := Round(GridAnnualAmount / TotalContractDaysWithGrace);

        // Calculate the difference per day
        DifferencePerDayRent := PerDayRentWithoutGracePeriod - PerDayRentWithGracePeriod;

        // Calculate total adjustment value for the missed days
        GracePeriodAdjustmentValue := DifferencePerDayRent * MissedDays;

        // Calculate grace period dates
        GraceStartDate := ContractRec."Grace Start Date";
        GraceEndDate := ContractRec."Grace End Date";

        // Check if grace period falls within missed allocation period
        // Grace period should be inserted only if grace start date and grace end date 
        // overlap with the missed allocation period (contract start date to previous month end)
        ShouldInsertGraceLine := (ContractRec."Grace Period" > 0) and
                                (GraceStartDate <> 0D) and (GraceEndDate <> 0D) and
                                (GraceStartDate <= PreviousMonthEnd) and
                                (GraceEndDate >= ContractStartDate);

        // -----------------------------------------------
        // Insert missed allocation line (without grace period adjustment)
        // -----------------------------------------------
        FilteredContractRec.Init();
        FilteredContractRec."Line No." := NewLineNo;
        FilteredContractRec."Header No." := Rec."No.";
        FilteredContractRec."Property Name" := ContractRec."Property Name";
        FilteredContractRec."Contract Id" := ContractRec."Contract ID";
        FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
        FilteredContractRec."Customer Name" := ContractRec."Customer Name";
        FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
        FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
        FilteredContractRec."Grace Days" := ContractRec."Grace Period";
        FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
        FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";
        FilteredContractRec.Description := 'Missed Revenue';

        if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
            FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
        else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
            FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
        else
            FilteredContractRec."Single Unit Names" := '';

        // Add Termination Date
        if TerminationDate = 0D then
            FilteredContractRec."Termination Date" := 0D
        else
            FilteredContractRec."Termination Date" := TerminationDate;

        SuspensionRec.Reset();
        SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
        if SuspensionRec.FindFirst() then begin
            FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
            FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
        end;

        FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
        FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
        FilteredContractRec."No Of Days" := MissedDays;
        FilteredContractRec."Per Day Rent" := Round(PerDayRent);
        FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount"; // Use grid's annual amount
        FilteredContractRec."Annual Amount" := GridAnnualAmount;
        FilteredContractRec."Total Value" := MissedDays * FilteredContractRec."Per Day Rent";
        FilteredContractRec."Owner Share" := MissedDays * FilteredContractRec."Per Day Rent";
        FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
        FilteredContractRec."Posting Month" := PreviousMonthNo;
        FilteredContractRec."Posting Year" := PreviousYearNo;
        FilteredContractRec."Posting Period" := GetMonthName(PreviousMonthNo) + ' ' +
            Format(PreviousYearNo) + ' ' + '-' + ' ' + GetMonthName(PreviousMonthNo) + ' ' + Format(PreviousYearNo);
        FilteredContractRec."Owner Name" := ContractRec."Owner's Name";
        FilteredContractRec.Insert();

        // -----------------------------------------------
        // Insert grace period adjustment line (negative allocation) for missed days
        // Only if grace period dates overlap with the missed allocation period
        // -----------------------------------------------
        if ShouldInsertGraceLine then begin
            NewLineNo := GetNextLineNo();

            FilteredContractRec.Init();
            FilteredContractRec."Line No." := NewLineNo;
            FilteredContractRec."Header No." := Rec."No.";
            FilteredContractRec."Property Name" := ContractRec."Property Name";
            FilteredContractRec."Contract Id" := ContractRec."Contract ID";
            FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
            FilteredContractRec."Customer Name" := ContractRec."Customer Name";
            FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
            FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
            FilteredContractRec."Grace Days" := ContractRec."Grace Period";
            FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
            FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";
            FilteredContractRec.Description := 'Grace Period';

            if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
            else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
            else
                FilteredContractRec."Single Unit Names" := '';
            // Add Termination Date
            if TerminationDate = 0D then
                FilteredContractRec."Termination Date" := 0D
            else
                FilteredContractRec."Termination Date" := TerminationDate;

            if SuspensionRec.FindFirst() then begin
                FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
                FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
            end;

            FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
            FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
            FilteredContractRec."No Of Days" := MissedDays;
            FilteredContractRec."Per Day Rent" := -DifferencePerDayRent; // Negative value
            FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount";
            FilteredContractRec."Annual Amount" := GridAnnualAmount;
            FilteredContractRec."Total Value" := -GracePeriodAdjustmentValue; // Negative adjustment
            FilteredContractRec."Owner Share" := -GracePeriodAdjustmentValue; // Negative adjustment
            FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
            FilteredContractRec."Posting Month" := PreviousMonthNo;
            FilteredContractRec."Posting Year" := PreviousYearNo;
            FilteredContractRec."Posting Period" := GetMonthName(PreviousMonthNo) + ' ' +
                Format(PreviousYearNo) + ' ' + '-' + ' ' + GetMonthName(PreviousMonthNo) + ' ' + Format(PreviousYearNo);
            FilteredContractRec."Owner Name" := ContractRec."Owner's Name";
            FilteredContractRec.Insert();
        end;
    end;

    // Helper function to get month name from month number
    procedure GetMonthName(MonthNo: Integer): Text
    begin
        case MonthNo of
            1:
                exit('January');
            2:
                exit('February');
            3:
                exit('March');
            4:
                exit('April');
            5:
                exit('May');
            6:
                exit('June');
            7:
                exit('July');
            8:
                exit('August');
            9:
                exit('September');
            10:
                exit('October');
            11:
                exit('November');
            12:
                exit('December');
            else
                exit(Format(MonthNo)); // Fallback to number if invalid
        end;
    end;


    //---------------Fetch Contracts--------------//

    // Then modify the FetchContracts procedure to use this
    procedure FetchContracts()
    var
        // Record variables for different data sources
        FilterHeader: Record "Revenue Allocation Details";           // Header record
        ContractRec: Record "Tenancy Contract";                     // Main contract record
        FilteredContractRec: Record "Revenue Allocation SubGrid";    // Target allocation table
        SuspensionRec: Record SuspendReasonTable;                   // Suspension information
        FinalCalculationRec: Record "Final Calculation";            // Final calculation data

        // Rent type record variables
        SingleUnitRent: Record "TC Single Unit Rent SubPage";        // Single unit rent records
        MultiUnitRent: Record "TC Single LumAnnualAmnt SP";         // Multi unit rent records
        MergedSingleRent: Record "TC Merge SameSqure SubPage";      // Merged single rent records
        MergedMultiRent: Record "TC Merge DifferentSq SubPage";     // Merged multi rent records
        SpecialRent: Record "TC Merge LumAnnualAmount SP";          // Special rent records

        // Date and calculation variables
        SelectedMonthStart: Date;                                   // First day of selected month
        SelectedMonthEnd: Date;                                     // Last day of selected month
        MonthNo: Integer;                                           // Selected month number
        FinancialYear: Integer;                                     // Selected financial year
        LineNo: Integer;                                            // Line number for allocations
        TerminationDate: Date;                                      // Contract termination date
        SuspensionDate: Date;
        ShouldProcessContract: Boolean;                             // Flag to determine if contract should be processed
    begin
        // Clear any existing allocation data before processing
        ClearSubgridData();

        // Get month and year from current record
        MonthNo := Rec.Month;
        FinancialYear := Rec."Financial Year";

        // Calculate date range for the selected month
        SelectedMonthStart := DMY2Date(01, MonthNo, FinancialYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Filter contracts to include both Active and Terminated contracts
        ContractRec.SetFilter(ContractRec."Tenant Contract Status", '%1|%2|%3',
            ContractRec."Tenant Contract Status"::Active,
            ContractRec."Tenant Contract Status"::Terminated,
            ContractRec."Tenant Contract Status"::Suspended);

        if ContractRec.FindSet() then begin
            repeat
                // Flag to determine if contract should be processed
                TerminationDate := 0D;
                SuspensionDate := 0D;
                ShouldProcessContract := false;

                // Get termination date from Final Calculation table first
                FinalCalculationRec.Reset();
                FinalCalculationRec.SetRange("Contract ID", ContractRec."Contract ID");
                if FinalCalculationRec.FindFirst() then
                    TerminationDate := FinalCalculationRec."Termination Date"
                else
                    TerminationDate := 0D;

                // Get Suspension Start Date - FIXED: Better error handling
                SuspensionRec.Reset();
                SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
                if SuspensionRec.FindFirst() then
                    SuspensionDate := SuspensionRec.DateEffective
                else
                    SuspensionDate := 0D;  // Explicitly set to 0D if not found

                // Check contract status and decide if it should be processed
                case ContractRec."Tenant Contract Status" of
                    ContractRec."Tenant Contract Status"::Active:
                        ShouldProcessContract := true;

                    ContractRec."Tenant Contract Status"::Terminated:
                        if (TerminationDate >= SelectedMonthStart) and (TerminationDate <= SelectedMonthEnd) then
                            ShouldProcessContract := true;

                    ContractRec."Tenant Contract Status"::Suspended:
                        // FIXED: Added null date check and improved logic
                        if (SuspensionDate <> 0D) and
                           (SuspensionDate >= SelectedMonthStart) and
                           (SuspensionDate <= SelectedMonthEnd) then
                            ShouldProcessContract := true;
                end;

                // Process contract only if it meets the criteria
                if ShouldProcessContract then begin
                    // PURPOSE: Process only contracts that overlap with selected month
                    // LOGIC: Contract start date <= month end AND contract end date >= month start
                    if ((ContractRec."Contract Start Date" <= SelectedMonthEnd) and
                        (ContractRec."Contract End Date" >= SelectedMonthStart)) then begin

                        // Handle missed allocation from previous month (if contract started mid-month)
                        HandleMissedAllocation(ContractRec, MonthNo, FinancialYear);

                        // Handle suspension recovery allocation (new functionality)
                        HandleSuspensionRecoveryAllocation(ContractRec, MonthNo, FinancialYear);

                        // Process Single Unit Rent records
                        SingleUnitRent.Reset();
                        SingleUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if SingleUnitRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Single Unit Rent record
                                InsertAllocationLine(
                                    ContractRec,
                                    SingleUnitRent."Start Date",
                                    SingleUnitRent."End Date",
                                    SingleUnitRent."Number of Days",
                                    SingleUnitRent."Per Day Rent",
                                    SingleUnitRent."Final Annual Amount",
                                    SingleUnitRent."Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until SingleUnitRent.Next() = 0;
                        end;

                        // Check Multi Unit Rent grid
                        MultiUnitRent.Reset();
                        MultiUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if MultiUnitRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Multi Unit Rent record
                                InsertAllocationLine(
                                    ContractRec,
                                    MultiUnitRent."SL_Start Date",
                                    MultiUnitRent."SL_End Date",
                                    MultiUnitRent."SL_Number of Days",
                                    MultiUnitRent."SL_Per Day Rent",
                                    MultiUnitRent."SL_Final Annual Amount",
                                    MultiUnitRent."SL_Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until MultiUnitRent.Next() = 0;
                        end;

                        // Check Merged Single Rent grid
                        MergedSingleRent.Reset();
                        MergedSingleRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if MergedSingleRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Merged Single Rent record
                                InsertAllocationLine(
                                    ContractRec,
                                    MergedSingleRent."MS_Start Date",
                                    MergedSingleRent."MS_End Date",
                                    MergedSingleRent."MS_Number of Days",
                                    MergedSingleRent."MS_Per Day Rent",
                                    MergedSingleRent."MS_Final Annual Amount",
                                    MergedSingleRent."MS_Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until MergedSingleRent.Next() = 0;
                        end;

                        // Check Merged Multi Rent grid
                        MergedMultiRent.Reset();
                        MergedMultiRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if MergedMultiRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Merged Multi Rent record
                                InsertAllocationLine(
                                    ContractRec,
                                    MergedMultiRent."MD_Start Date",
                                    MergedMultiRent."MD_End Date",
                                    MergedMultiRent."MD_Number of Days",
                                    MergedMultiRent."MD_Per Day Rent",
                                    MergedMultiRent."MD_Final Annual Amount",
                                    MergedMultiRent."MD_Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until MergedMultiRent.Next() = 0;
                        end;

                        // Check Special Rent grid
                        SpecialRent.Reset();
                        SpecialRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if SpecialRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Special Rent record
                                InsertAllocationLine(
                                    ContractRec,
                                    SpecialRent."ML_Start Date",
                                    SpecialRent."ML_End Date",
                                    SpecialRent."ML_Number of Days",
                                    SpecialRent."ML_Per Day Rent",
                                    SpecialRent."ML_Final Annual Amount",
                                    SpecialRent."ML_Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until SpecialRent.Next() = 0;
                        end;
                    end;
                end;
            until ContractRec.Next() = 0;
        end;
        CalculateTotals();
    end;

    //---------------Handle Suspension Recovery Allocation--------------//
    procedure HandleSuspensionRecoveryAllocation(
    ContractRec: Record "Tenancy Contract";
    MonthNo: Integer;
    FinancialYear: Integer)
    var
        SuspensionRec: Record SuspendReasonTable;
        CurrentMonthStart: Date;
        CurrentMonthEnd: Date;
        SuspensionStartDate: Date;
        SuspensionEndDate: Date;
        RecoveryStartDate: Date;
        RecoveryEndDate: Date;
        SingleUnitRent: Record "TC Single Unit Rent SubPage";
        MultiUnitRent: Record "TC Single LumAnnualAmnt SP";
        MergedSingleRent: Record "TC Merge SameSqure SubPage";
        MergedMultiRent: Record "TC Merge DifferentSq SubPage";
        SpecialRent: Record "TC Merge LumAnnualAmount SP";
        FinalCalculationRec: Record "Final Calculation";
        TerminationDate: Date;
        LineNo: Integer;
    begin
        // Calculate current month date range
        CurrentMonthStart := DMY2Date(1, MonthNo, FinancialYear);
        CurrentMonthEnd := CALCDATE('<CM>', CurrentMonthStart);

        // Check if contract was suspended and is now active
        SuspensionRec.Reset();
        SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
        SuspensionRec.SetFilter(SuspensionEndDate, '<%1', CurrentMonthStart); // Suspension ended before current month

        if SuspensionRec.FindLast() then begin
            SuspensionStartDate := SuspensionRec.DateEffective;
            SuspensionEndDate := SuspensionRec.SuspensionEndDate;

            // Recovery period starts from suspension start date to suspension end date
            RecoveryStartDate := SuspensionStartDate;
            RecoveryEndDate := SuspensionEndDate;

            // Validate that suspension period is valid and ended
            if (SuspensionEndDate <> 0D) and (SuspensionEndDate < CurrentMonthStart) then begin

                // Retrieve Termination Date from Final Calculation
                FinalCalculationRec.Reset();
                FinalCalculationRec.SetRange("Contract ID", ContractRec."Contract ID");
                if FinalCalculationRec.FindFirst() then
                    TerminationDate := FinalCalculationRec."Termination Date"
                else
                    TerminationDate := 0D;

                // Process each rent type for suspension recovery allocation
                // Check Single Unit Rent grid
                SingleUnitRent.Reset();
                SingleUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
                if SingleUnitRent.FindSet() then begin
                    repeat
                        if (SingleUnitRent."Start Date" <= RecoveryEndDate) and (SingleUnitRent."End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLine(
                                ContractRec,
                                SingleUnitRent."Start Date",
                                SingleUnitRent."End Date",
                                SingleUnitRent."Number of Days",
                                SingleUnitRent."Per Day Rent",
                                SingleUnitRent."Final Annual Amount",
                                SingleUnitRent."Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Single Unit Rent Recovery');
                        end;
                    until SingleUnitRent.Next() = 0;
                end;

                // Check Multi Unit Rent grid
                MultiUnitRent.Reset();
                MultiUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
                if MultiUnitRent.FindSet() then begin
                    repeat
                        if (MultiUnitRent."SL_Start Date" <= RecoveryEndDate) and (MultiUnitRent."SL_End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLine(
                                ContractRec,
                                MultiUnitRent."SL_Start Date",
                                MultiUnitRent."SL_End Date",
                                MultiUnitRent."SL_Number of Days",
                                MultiUnitRent."SL_Per Day Rent",
                                MultiUnitRent."SL_Final Annual Amount",
                                MultiUnitRent."SL_Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Multi Unit Rent Recovery');
                        end;
                    until MultiUnitRent.Next() = 0;
                end;

                // Check Merged Single Rent grid
                MergedSingleRent.Reset();
                MergedSingleRent.SetRange("Contract ID", ContractRec."Contract ID");
                if MergedSingleRent.FindSet() then begin
                    repeat
                        if (MergedSingleRent."MS_Start Date" <= RecoveryEndDate) and (MergedSingleRent."MS_End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLine(
                                ContractRec,
                                MergedSingleRent."MS_Start Date",
                                MergedSingleRent."MS_End Date",
                                MergedSingleRent."MS_Number of Days",
                                MergedSingleRent."MS_Per Day Rent",
                                MergedSingleRent."MS_Final Annual Amount",
                                MergedSingleRent."MS_Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Merged Single Rent Recovery');
                        end;
                    until MergedSingleRent.Next() = 0;
                end;

                // Check Merged Multi Rent grid
                MergedMultiRent.Reset();
                MergedMultiRent.SetRange("Contract ID", ContractRec."Contract ID");
                if MergedMultiRent.FindSet() then begin
                    repeat
                        if (MergedMultiRent."MD_Start Date" <= RecoveryEndDate) and (MergedMultiRent."MD_End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLine(
                                ContractRec,
                                MergedMultiRent."MD_Start Date",
                                MergedMultiRent."MD_End Date",
                                MergedMultiRent."MD_Number of Days",
                                MergedMultiRent."MD_Per Day Rent",
                                MergedMultiRent."MD_Final Annual Amount",
                                MergedMultiRent."MD_Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Merged Multi Rent Recovery');
                        end;
                    until MergedMultiRent.Next() = 0;
                end;

                // Check Special Rent grid
                SpecialRent.Reset();
                SpecialRent.SetRange("Contract ID", ContractRec."Contract ID");
                if SpecialRent.FindSet() then begin
                    repeat
                        if (SpecialRent."ML_Start Date" <= RecoveryEndDate) and (SpecialRent."ML_End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLine(
                                ContractRec,
                                SpecialRent."ML_Start Date",
                                SpecialRent."ML_End Date",
                                SpecialRent."ML_Number of Days",
                                SpecialRent."ML_Per Day Rent",
                                SpecialRent."ML_Final Annual Amount",
                                SpecialRent."ML_Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Special Rent Recovery');
                        end;
                    until SpecialRent.Next() = 0;
                end;
            end;
        end;
    end;

    //---------------Insert Suspension Recovery Line--------------//
    procedure InsertSuspensionRecoveryLine(
    ContractRec: Record "Tenancy Contract";
    MultiYearStartDate: Date;
    MultiYearEndDate: Date;
    NoOfDays: Integer;
    PerDayRent: Decimal;
    TotalAnnualAmount: Decimal;
    OwnerShareAmount: Decimal;
    TerminationDate: Date;
    LineNo: Integer;
    MonthNo: Integer;
    FinancialYear: Integer;
    RecoveryStartDate: Date;
    RecoveryEndDate: Date;
    RecoveryType: Text)
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        SuspensionRec: Record SuspendReasonTable;
        CalculatedRecoveryDays: Integer;
        NewLineNo: Integer;
        GridAnnualAmount: Decimal;
        RecoveryAmount: Decimal;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
    begin
        // Get new line number
        NewLineNo := GetNextLineNo();

        // Use the annual amount from the grid record
        GridAnnualAmount := TotalAnnualAmount;

        // Calculate effective recovery period
        // Use the latest start date and earliest end date
        EffectiveStartDate := RecoveryStartDate;
        if MultiYearStartDate > EffectiveStartDate then
            EffectiveStartDate := MultiYearStartDate;

        EffectiveEndDate := RecoveryEndDate;
        if MultiYearEndDate < EffectiveEndDate then
            EffectiveEndDate := MultiYearEndDate;

        // Calculate recovery days
        if EffectiveStartDate <= EffectiveEndDate then
            CalculatedRecoveryDays := EffectiveEndDate - EffectiveStartDate + 1
        else
            CalculatedRecoveryDays := 0;

        // Only insert if there are days to recover
        if CalculatedRecoveryDays > 0 then begin
            // Calculate recovery amount
            RecoveryAmount := CalculatedRecoveryDays * PerDayRent;

            // Insert suspension recovery allocation line
            FilteredContractRec.Init();
            FilteredContractRec."Line No." := NewLineNo;
            FilteredContractRec."Header No." := Rec."No.";
            FilteredContractRec."Property Name" := ContractRec."Property Name";
            FilteredContractRec."Contract Id" := ContractRec."Contract ID";
            FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
            FilteredContractRec."Customer Name" := ContractRec."Customer Name";
            FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
            FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
            FilteredContractRec."Grace Days" := ContractRec."Grace Period";
            FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
            FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";

            if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
            else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
            else
                FilteredContractRec."Single Unit Names" := '';

            // Add Termination Date
            if TerminationDate = 0D then
                FilteredContractRec."Termination Date" := 0D
            else
                FilteredContractRec."Termination Date" := TerminationDate;

            // Add suspension information
            SuspensionRec.Reset();
            SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
            if SuspensionRec.FindFirst() then begin
                FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
                FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
            end;

            FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
            FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
            FilteredContractRec."No Of Days" := CalculatedRecoveryDays;
            FilteredContractRec."Per Day Rent" := Round(PerDayRent);
            FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount";
            FilteredContractRec."Annual Amount" := GridAnnualAmount;
            FilteredContractRec."Total Value" := RecoveryAmount;
            FilteredContractRec."Owner Share" := RecoveryAmount;
            FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
            FilteredContractRec."Posting Month" := MonthNo;
            FilteredContractRec."Posting Year" := FinancialYear;
            FilteredContractRec.Description := 'Suspension';
            FilteredContractRec."Posting Period" := 'Suspension Recovery - ' + Format(MonthNo) + ' ' + Format(FinancialYear);
            FilteredContractRec."Owner Name" := ContractRec."Owner's Name";

            // Add a note to indicate this is suspension recovery
            // If you have a description field, uncomment below:
            // FilteredContractRec."Description" := RecoveryType + ' - Recovery Period: ' + 
            //     Format(EffectiveStartDate) + ' to ' + Format(EffectiveEndDate);

            FilteredContractRec.Insert();
        end;
    end;

    procedure CalculateAndStoreTotalRevenue()
    var
        revenueItemLine: Record "Revenue Recognition Details";
        revenueAllocLine: Record "Revenue Allocation Subgrid";
    begin
        Clear(totalcontractAmounts);
        Clear(totalamounts);

        revenueItemLine.SetRange("RR_No.", Rec."No.");
        if revenueItemLine.FindSet() then
            repeat
                totalcontractAmounts += revenueItemLine."Contract Amount";
                totalamounts += revenueItemLine."Total Value";
                TotalAnnualAmounts += revenueItemLine."Annual Amount";
                TotalFinalAnnualAmounts += revenueItemLine."Final Annual Amount";



            until revenueItemLine.Next() = 0;


        revenueAllocLine.SetRange("Header No.", Rec."No.");
        if revenueAllocLine.FindSet() then
            repeat
                totalcontractAmountsss += revenueAllocLine."Contract Amount";
                totalamountsss += revenueAllocLine."Total Value";
                totalannualamountsss += revenueAllocLine."Annual Amount";
                totalfinalannualamountsss += revenueAllocLine."Final Annual Amount";
            until revenueAllocLine.Next() = 0;


        totalcombinecontractAmounts := totalcontractAmountsss + totalcontractAmounts;
        totalcombineamounts := totalamountsss + totalamounts;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalculateAndStoreTotalRevenue();
    end;









    //////////////////////////////FIXED MONTH RENT////////////////////////////////////////////////////////////////////////////////////
    procedure CalculateDaysInSelectedMonths(
           ContractStartDate: Date;
           ContractEndDate: Date;
           MultiYearStartDate: Date;
           MultiYearEndDate: Date;
           SelectedMonth: Integer;
           SelectedYear: Integer): Integer
    var
        StartDate: Date;
        EndDate: Date;
        MonthStartDate: Date;
        MonthEndDate: Date;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
    begin
        // Get first day of selected month (without +1, assuming SelectedMonth is correct)
        MonthStartDate := DMY2Date(1, SelectedMonth, SelectedYear);
        // Get last day of selected month
        MonthEndDate := CALCDATE('<+1M-1D>', MonthStartDate);

        // Return 0 if multi-year period is completely outside selected month
        if (MultiYearStartDate > MonthEndDate) or (MultiYearEndDate < MonthStartDate) then
            exit(0);

        // Determine effective start date for the month
        // Use the latest of: MonthStart, MultiYearStart, ContractStart
        EffectiveStartDate := MonthStartDate;
        if MultiYearStartDate > EffectiveStartDate then
            EffectiveStartDate := MultiYearStartDate;
        if ContractStartDate > EffectiveStartDate then
            EffectiveStartDate := ContractStartDate;

        // Determine effective end date for the month  
        // Use the earliest of: MonthEnd, MultiYearEnd, ContractEnd
        EffectiveEndDate := MonthEndDate;
        if MultiYearEndDate < EffectiveEndDate then
            EffectiveEndDate := MultiYearEndDate;
        if ContractEndDate < EffectiveEndDate then
            EffectiveEndDate := ContractEndDate;

        // Ensure we don't have invalid date range
        if EffectiveStartDate > EffectiveEndDate then
            exit(0);

        // Calculate inclusive number of days
        exit(EffectiveEndDate - EffectiveStartDate + 1);
    end;


    //---------------Should Keep Entry--------------//
    procedure ShouldKeepEntrys(StartDate: Date; EndDate: Date): Boolean
    var
        CheckDate: Date;
        LastDayOfMonth: Date;
        FirstDayOfMonth: Date;
    begin
        // Get first day of selected month
        FirstDayOfMonth := DMY2Date(1, Rec.Month, Rec."Financial Year");

        // Get last day of selected month
        LastDayOfMonth := CALCDATE('<+1M-1D>', FirstDayOfMonth);

        // Check if selected month's date range overlaps with the given date range
        // A period overlaps if:
        if (StartDate <= LastDayOfMonth) and (EndDate >= FirstDayOfMonth) then
            exit(true);

        exit(false);
    end;


    //---------------Insert Allocation Line--------------//

    // Helper procedure to insert allocation line

    // Modified InsertAllocationLine procedure with grace period date check
    // Modified InsertAllocationLine procedure with grace period date check
    procedure InsertAllocationLines(
     ContractRec: Record "Tenancy Contract";
     MultiYearStartDate: Date;
     MultiYearEndDate: Date;
     NoOfDays: Integer;
     PerDayRent: Decimal;
     TotalAnnualAmount: Decimal;
     OwnerShareAmount: Decimal;
     TerminationDate: Date;
     LineNo: Integer;
     MonthNo: Integer;
     FinancialYear: Integer)
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        SuspensionRec: Record SuspendReasonTable;
        CalculatedDays: Integer;
        NewLineNo: Integer;
        PerDayRentWithoutGracePeriod: Decimal;
        PerDayRentWithGracePeriod: Decimal;
        TotalContractDays: Integer;
        TotalContractDaysWithGrace: Integer;
        DifferencePerDayRent: Decimal;
        GracePeriodAdjustmentValue: Decimal;
        GridAnnualAmount: Decimal;
        // New variables for grace period date check
        GraceStartDate: Date;
        GraceEndDate: Date;
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
        ShouldInsertGraceLine: Boolean;
        permonthrent: Decimal;
        AdjustedStartDate: Date; // 🔹 new
        AdjustedEndDate: Date;   // 🔹 new
        SuspensionStartDateInMonth: Date; // 🔹 ADDED   
    begin
        // Check if entry should be kept based on date range
        if not ShouldKeepEntry(MultiYearStartDate, MultiYearEndDate) then
            exit;

        // Calculate selected month date range
        SelectedMonthStart := DMY2Date(1, MonthNo, FinancialYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Calculate grace period dates
        GraceStartDate := ContractRec."Grace Start Date";
        GraceEndDate := ContractRec."Grace End Date";

        // Check if grace period falls within selected month
        // Grace period should be inserted only if grace start date and grace end date 
        // overlap with the selected month
        ShouldInsertGraceLine := (ContractRec."Grace Period" > 0) and
                                (GraceStartDate <> 0D) and (GraceEndDate <> 0D) and
                                (GraceStartDate <= SelectedMonthEnd) and
                                (GraceEndDate >= SelectedMonthStart);

        // Get new line number
        NewLineNo := GetNextLineNo();

        // 🔹 NEW: Calculate AdjustedStartDate & AdjustedEndDate
        AdjustedStartDate := MultiYearStartDate;
        if AdjustedStartDate < SelectedMonthStart then
            AdjustedStartDate := SelectedMonthStart;

        AdjustedEndDate := MultiYearEndDate;
        if AdjustedEndDate > SelectedMonthEnd then
            AdjustedEndDate := SelectedMonthEnd;

        if (TerminationDate <> 0D) and (AdjustedEndDate > TerminationDate) then
            AdjustedEndDate := TerminationDate;

        // 🔹 Adjust for Suspension Start
        SuspensionRec.Reset();
        SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
        if SuspensionRec.FindFirst() then begin
            if (SuspensionRec.DateEffective <> 0D) and
               (SuspensionRec.DateEffective >= SelectedMonthStart) and
               (SuspensionRec.DateEffective <= SelectedMonthEnd) then begin
                SuspensionStartDateInMonth := SuspensionRec.DateEffective;
                AdjustedEndDate := SuspensionRec.DateEffective - 1; // 🔹 ADDED
            end;
        end;

        if (AdjustedStartDate <= AdjustedEndDate) then
            CalculatedDays := AdjustedEndDate - AdjustedStartDate + 1
        else
            CalculatedDays := 0;

        // Calculate the actual number of days for the selected month
        // CalculatedDays := CalculateDaysInSelectedMonths(
        //     ContractRec."Contract Start Date",
        //     ContractRec."Contract End Date",
        //     MultiYearStartDate,
        //     MultiYearEndDate,
        //     MonthNo,
        //     FinancialYear
        // );

        // Get the days in the specific grid record's date range
        TotalContractDays := MultiYearEndDate - MultiYearStartDate + 1;

        // Calculate Total Contract Days (with grace period)
        TotalContractDaysWithGrace := TotalContractDays + ContractRec."Grace Period";

        // Use the annual amount from the grid record instead of the main contract
        GridAnnualAmount := TotalAnnualAmount;

        // Calculate Per Day Rent without Grace Period (using grid's annual amount)
        PerDayRentWithoutGracePeriod := Round(GridAnnualAmount / TotalContractDays);

        // Calculate Per Day Rent with Grace Period (using grid's annual amount)
        PerDayRentWithGracePeriod := Round(GridAnnualAmount / TotalContractDaysWithGrace);

        // Calculate the difference per day
        DifferencePerDayRent := PerDayRentWithoutGracePeriod - PerDayRentWithGracePeriod;

        // Calculate total adjustment value for the month
        GracePeriodAdjustmentValue := DifferencePerDayRent * CalculatedDays;

        // -----------------------------------------------
        // Insert main allocation line (without grace period adjustment)
        // -----------------------------------------------
        FilteredContractRec.Init();
        FilteredContractRec."Line No." := NewLineNo;
        FilteredContractRec."Header No." := Rec."No.";
        FilteredContractRec."Property Name" := ContractRec."Property Name";
        FilteredContractRec."Contract Id" := ContractRec."Contract ID";
        FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
        FilteredContractRec."Customer Name" := ContractRec."Customer Name";
        FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
        FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";

        if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
            FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
        else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
            FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
        else
            FilteredContractRec."Single Unit Names" := '';


        //FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name";
        FilteredContractRec."Grace Days" := ContractRec."Grace Period";
        FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
        FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";
        FilteredContractRec.Description := 'Regular';

        // Add Termination Date
        if TerminationDate = 0D then
            FilteredContractRec."Termination Date" := 0D
        else
            FilteredContractRec."Termination Date" := TerminationDate;

        SuspensionRec.Reset();
        SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
        if SuspensionRec.FindFirst() then begin
            FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
            FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
        end;

        FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
        FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
        FilteredContractRec."No Of Days" := CalculatedDays;
        FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount"; // Use grid's annual amount
        FilteredContractRec."Annual Amount" := GridAnnualAmount;
        FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;

        permonthrent := FilteredContractRec."Final Annual Amount" / 12;
        FilteredContractRec."Per Month Rent" := calculatepermonthrent(permonthrent, CalculatedDays, MonthNo, FinancialYear); // Use the per day rent passed from the grid
        FilteredContractRec."Total Value" := FilteredContractRec."Per Month Rent";
        FilteredContractRec."Owner Share" := FilteredContractRec."Per Month Rent";

        FilteredContractRec."Posting Month" := MonthNo;
        FilteredContractRec."Posting Year" := FinancialYear;
        FilteredContractRec."Posting Period" := Format(FilteredContractRec."Posting Month") +
            ' ' + Format(FilteredContractRec."Posting Year") + ' ' + '-' + ' ' +
            Format(FilteredContractRec."Posting Month") + ' ' + Format(FilteredContractRec."Posting Year");
        FilteredContractRec."Owner Name" := ContractRec."Owner's Name";
        FilteredContractRec.Insert();

        // -----------------------------------------------
        // Insert grace period adjustment line (negative allocation)
        // Only if grace period dates fall within selected month
        // -----------------------------------------------
        if ShouldInsertGraceLine then begin
            NewLineNo := GetNextLineNo();

            FilteredContractRec.Init();
            FilteredContractRec."Line No." := NewLineNo;
            FilteredContractRec."Header No." := Rec."No.";
            FilteredContractRec."Property Name" := ContractRec."Property Name";
            FilteredContractRec."Contract Id" := ContractRec."Contract ID";
            FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
            FilteredContractRec."Customer Name" := ContractRec."Customer Name";
            FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
            FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
            FilteredContractRec."Grace Days" := ContractRec."Grace Period";
            FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
            FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";
            FilteredContractRec.Description := 'Grace Period';

            if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
            else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
            else
                FilteredContractRec."Single Unit Names" := '';


            // Add Termination Date
            if TerminationDate = 0D then
                FilteredContractRec."Termination Date" := 0D
            else
                FilteredContractRec."Termination Date" := TerminationDate;

            if SuspensionRec.FindFirst() then begin
                FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
                FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
            end;

            FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
            FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
            FilteredContractRec."No Of Days" := CalculatedDays;
            FilteredContractRec."Per Month Rent" := -DifferencePerDayRent; // Negative value
            FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount"; // Use grid's annual amount
            FilteredContractRec."Annual Amount" := GridAnnualAmount;
            FilteredContractRec."Total Value" := -GracePeriodAdjustmentValue; // Negative adjustment
            FilteredContractRec."Owner Share" := -GracePeriodAdjustmentValue; // Negative adjustment
            FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
            FilteredContractRec."Posting Month" := MonthNo;
            FilteredContractRec."Posting Year" := FinancialYear;
            FilteredContractRec."Posting Period" := Format(FilteredContractRec."Posting Month") +
                ' ' + Format(FilteredContractRec."Posting Year") + ' ' + '-' + ' ' +
                Format(FilteredContractRec."Posting Month") + ' ' + Format(FilteredContractRec."Posting Year");
            FilteredContractRec."Owner Name" := ContractRec."Owner's Name";
            // Add a description to indicate this is a grace period adjustment
            // FilteredContractRec."Description" := 'Grace Period Adjustment';
            FilteredContractRec.Insert();
        end;
    end;



    procedure calculatepermonthrent(permonthrent: Decimal; CalculatedDays: Integer; MonthNo: Integer; FinancialYear: Integer): Decimal
    var
        revenuerecognition: Record "Revenue Recognition";
        MonthlyRate: Decimal;
    begin

        if CalculatedDays < revenuerecognition.GetDaysInMonthss(DMY2Date(1, MonthNo, FinancialYear)) then begin
            MonthlyRate := Round(permonthrent / revenuerecognition.GetDaysInMonthss(DMY2Date(1, MonthNo, FinancialYear)) * CalculatedDays);
        end else begin
            MonthlyRate := permonthrent;
        end;
        exit(MonthlyRate);
    end;

    procedure calculatepermonthrents(permonthrent: Decimal; CalculatedDays: Integer; PreviousMonthNo: Integer; PreviousYearNo: Integer): Decimal
    var
        revenuerecognition: Record "Revenue Recognition";
        MonthlyRate: Decimal;
    begin

        if CalculatedDays < revenuerecognition.GetDaysInMonthss(DMY2Date(1, PreviousMonthNo, PreviousYearNo)) then begin
            MonthlyRate := Round(permonthrent / revenuerecognition.GetDaysInMonthss(DMY2Date(1, PreviousMonthNo, PreviousYearNo)) * CalculatedDays);
        end else begin
            MonthlyRate := permonthrent;
        end;
        exit(MonthlyRate);
    end;

    procedure calculatepermonthrentss(permonthrent: Decimal; CalculatedRecoveryDays: Integer; MonthNo: Integer; FinancialYear: Integer): Decimal
    var
        revenuerecognition: Record "Revenue Recognition";
        MonthlyRate: Decimal;
    begin

        if CalculatedRecoveryDays < revenuerecognition.GetDaysInMonthss(DMY2Date(1, MonthNo, FinancialYear)) then begin
            MonthlyRate := Round(permonthrent / revenuerecognition.GetDaysInMonthss(DMY2Date(1, MonthNo, FinancialYear)) * CalculatedRecoveryDays);
        end else begin
            MonthlyRate := permonthrent;
        end;
        exit(MonthlyRate);
    end;


    // Add this new helper procedure to handle missed revenue allocations
    procedure HandleMissedAllocations(
     ContractRec: Record "Tenancy Contract";
     MonthNo: Integer;
     FinancialYear: Integer)
    var
        PreviousMonthNo: Integer;
        PreviousYearNo: Integer;
        PreviousMonthStart: Date;
        PreviousMonthEnd: Date;
        CurrentMonthStart: Date;
        CurrentMonthEnd: Date;
        ContractStartDate: Date;
        MissedDays: Integer;
        SingleUnitRent: Record "TC Single Unit Rent SubPage";
        MultiUnitRent: Record "TC Single LumAnnualAmnt SP";
        MergedSingleRent: Record "TC Merge SameSqure SubPage";
        MergedMultiRent: Record "TC Merge DifferentSq SubPage";
        SpecialRent: Record "TC Merge LumAnnualAmount SP";
        FinalCalculationRec: Record "Final Calculation";
        TerminationDate: Date;
        LineNo: Integer;
    begin
        // Calculate previous month and year
        if MonthNo = 1 then begin
            PreviousMonthNo := 12;
            PreviousYearNo := FinancialYear - 1;
        end else begin
            PreviousMonthNo := MonthNo - 1;
            PreviousYearNo := FinancialYear;
        end;

        // Calculate date ranges
        PreviousMonthStart := DMY2Date(1, PreviousMonthNo, PreviousYearNo);
        PreviousMonthEnd := CALCDATE('<CM>', PreviousMonthStart);
        CurrentMonthStart := DMY2Date(1, MonthNo, FinancialYear);
        CurrentMonthEnd := CALCDATE('<CM>', CurrentMonthStart);
        ContractStartDate := ContractRec."Contract Start Date";

        // Check if contract started in previous month
        if (ContractStartDate >= PreviousMonthStart) and (ContractStartDate <= PreviousMonthEnd) then begin
            // Contract started in previous month, so we need to allocate missed days
            MissedDays := PreviousMonthEnd - ContractStartDate + 1;

            // Retrieve Termination Date from Final Calculation
            FinalCalculationRec.Reset();
            FinalCalculationRec.SetRange("Contract ID", ContractRec."Contract ID");
            if FinalCalculationRec.FindFirst() then
                TerminationDate := FinalCalculationRec."Termination Date"
            else
                TerminationDate := 0D;

            // Process each rent type for missed allocation
            // Check Single Unit Rent grid
            SingleUnitRent.Reset();
            SingleUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
            if SingleUnitRent.FindSet() then begin
                repeat
                    if (SingleUnitRent."Start Date" <= PreviousMonthEnd) and (SingleUnitRent."End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLines(
                            ContractRec,
                            SingleUnitRent."Start Date",
                            SingleUnitRent."End Date",
                            SingleUnitRent."Number of Days",
                            SingleUnitRent."Per Day Rent",
                            SingleUnitRent."Final Annual Amount",
                            SingleUnitRent."Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until SingleUnitRent.Next() = 0;
            end;

            // Check Multi Unit Rent grid
            MultiUnitRent.Reset();
            MultiUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
            if MultiUnitRent.FindSet() then begin
                repeat
                    if (MultiUnitRent."SL_Start Date" <= PreviousMonthEnd) and (MultiUnitRent."SL_End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLines(
                            ContractRec,
                            MultiUnitRent."SL_Start Date",
                            MultiUnitRent."SL_End Date",
                            MultiUnitRent."SL_Number of Days",
                            MultiUnitRent."SL_Per Day Rent",
                            MultiUnitRent."SL_Final Annual Amount",
                            MultiUnitRent."SL_Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until MultiUnitRent.Next() = 0;
            end;

            // Check Merged Single Rent grid
            MergedSingleRent.Reset();
            MergedSingleRent.SetRange("Contract ID", ContractRec."Contract ID");
            if MergedSingleRent.FindSet() then begin
                repeat
                    if (MergedSingleRent."MS_Start Date" <= PreviousMonthEnd) and (MergedSingleRent."MS_End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLines(
                            ContractRec,
                            MergedSingleRent."MS_Start Date",
                            MergedSingleRent."MS_End Date",
                            MergedSingleRent."MS_Number of Days",
                            MergedSingleRent."MS_Per Day Rent",
                            MergedSingleRent."MS_Final Annual Amount",
                            MergedSingleRent."MS_Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until MergedSingleRent.Next() = 0;
            end;

            // Check Merged Multi Rent grid
            MergedMultiRent.Reset();
            MergedMultiRent.SetRange("Contract ID", ContractRec."Contract ID");
            if MergedMultiRent.FindSet() then begin
                repeat
                    if (MergedMultiRent."MD_Start Date" <= PreviousMonthEnd) and (MergedMultiRent."MD_End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLines(
                            ContractRec,
                            MergedMultiRent."MD_Start Date",
                            MergedMultiRent."MD_End Date",
                            MergedMultiRent."MD_Number of Days",
                            MergedMultiRent."MD_Per Day Rent",
                            MergedMultiRent."MD_Final Annual Amount",
                            MergedMultiRent."MD_Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until MergedMultiRent.Next() = 0;
            end;

            // Check Special Rent grid
            SpecialRent.Reset();
            SpecialRent.SetRange("Contract ID", ContractRec."Contract ID");
            if SpecialRent.FindSet() then begin
                repeat
                    if (SpecialRent."ML_Start Date" <= PreviousMonthEnd) and (SpecialRent."ML_End Date" >= ContractStartDate) then begin
                        InsertMissedAllocationLines(
                            ContractRec,
                            SpecialRent."ML_Start Date",
                            SpecialRent."ML_End Date",
                            SpecialRent."ML_Number of Days",
                            SpecialRent."ML_Per Day Rent",
                            SpecialRent."ML_Final Annual Amount",
                            SpecialRent."ML_Final Annual Amount",
                            TerminationDate,
                            LineNo,
                            PreviousMonthNo,
                            PreviousYearNo,
                            ContractStartDate,
                            PreviousMonthEnd);
                    end;
                until SpecialRent.Next() = 0;
            end;
        end;
    end;

    // Helper procedure to insert missed allocation lines
    // Helper procedure to insert missed allocation lines
    procedure InsertMissedAllocationLines(
     ContractRec: Record "Tenancy Contract";
     MultiYearStartDate: Date;
     MultiYearEndDate: Date;
     NoOfDays: Integer;
     PerDayRent: Decimal;
     TotalAnnualAmount: Decimal;
     OwnerShareAmount: Decimal;
     TerminationDate: Date;
     LineNo: Integer;
     PreviousMonthNo: Integer;
     PreviousYearNo: Integer;
     ContractStartDate: Date;
     PreviousMonthEnd: Date)
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        SuspensionRec: Record SuspendReasonTable;
        CalculatedDays: Integer;
        NewLineNo: Integer;
        PerDayRentWithoutGracePeriod: Decimal;
        PerDayRentWithGracePeriod: Decimal;
        TotalContractDays: Integer;
        TotalContractDaysWithGrace: Integer;
        DifferencePerDayRent: Decimal;
        GracePeriodAdjustmentValue: Decimal;
        GridAnnualAmount: Decimal;
        MissedDays: Integer;
        // New variables for grace period date check
        GraceStartDate: Date;
        GraceEndDate: Date;
        ShouldInsertGraceLine: Boolean;
        permonthrent: Decimal;
    begin
        // Calculate missed days
        MissedDays := PreviousMonthEnd - ContractStartDate + 1;

        // Get new line number
        NewLineNo := GetNextLineNo();

        // Use the annual amount from the grid record instead of the main contract
        GridAnnualAmount := TotalAnnualAmount;

        // Calculate Total Contract Days
        TotalContractDays := MultiYearEndDate - MultiYearStartDate + 1;

        // Calculate Total Contract Days (with grace period)
        TotalContractDaysWithGrace := TotalContractDays + ContractRec."Grace Period";

        // Calculate Per Day Rent without Grace Period (using grid's annual amount)
        PerDayRentWithoutGracePeriod := Round(GridAnnualAmount / TotalContractDays);

        // Calculate Per Day Rent with Grace Period (using grid's annual amount)
        PerDayRentWithGracePeriod := Round(GridAnnualAmount / TotalContractDaysWithGrace);

        // Calculate the difference per day
        DifferencePerDayRent := PerDayRentWithoutGracePeriod - PerDayRentWithGracePeriod;

        // Calculate total adjustment value for the missed days
        GracePeriodAdjustmentValue := DifferencePerDayRent * MissedDays;

        // Calculate grace period dates
        GraceStartDate := ContractRec."Grace Start Date";
        GraceEndDate := ContractRec."Grace End Date";

        // Check if grace period falls within missed allocation period
        // Grace period should be inserted only if grace start date and grace end date 
        // overlap with the missed allocation period (contract start date to previous month end)
        ShouldInsertGraceLine := (ContractRec."Grace Period" > 0) and
                                (GraceStartDate <> 0D) and (GraceEndDate <> 0D) and
                                (GraceStartDate <= PreviousMonthEnd) and
                                (GraceEndDate >= ContractStartDate);

        // -----------------------------------------------
        // Insert missed allocation line (without grace period adjustment)
        // -----------------------------------------------
        FilteredContractRec.Init();
        FilteredContractRec."Line No." := NewLineNo;
        FilteredContractRec."Header No." := Rec."No.";
        FilteredContractRec."Property Name" := ContractRec."Property Name";
        FilteredContractRec."Contract Id" := ContractRec."Contract ID";
        FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
        FilteredContractRec."Customer Name" := ContractRec."Customer Name";
        FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
        FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
        FilteredContractRec."Grace Days" := ContractRec."Grace Period";
        FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
        FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";
        FilteredContractRec.Description := 'Missed Revenue';

        if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
            FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
        else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
            FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
        else
            FilteredContractRec."Single Unit Names" := '';


        // Add Termination Date
        if TerminationDate = 0D then
            FilteredContractRec."Termination Date" := 0D
        else
            FilteredContractRec."Termination Date" := TerminationDate;

        SuspensionRec.Reset();
        SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
        if SuspensionRec.FindFirst() then begin
            FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
            FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
        end;

        FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
        FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
        FilteredContractRec."No Of Days" := MissedDays;
        FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount"; // Use grid's annual amount
        FilteredContractRec."Annual Amount" := GridAnnualAmount;
        FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
        permonthrent := FilteredContractRec."Final Annual Amount" / 12;
        FilteredContractRec."Per Month Rent" := calculatepermonthrents(permonthrent, CalculatedDays, PreviousMonthNo, PreviousYearNo); // Use the per day rent passed from the grid
        FilteredContractRec."Total Value" := MissedDays * FilteredContractRec."Per Month Rent";
        FilteredContractRec."Owner Share" := MissedDays * FilteredContractRec."Per Month Rent";
        FilteredContractRec."Posting Month" := PreviousMonthNo;
        FilteredContractRec."Posting Year" := PreviousYearNo;
        FilteredContractRec."Posting Period" := GetMonthName(PreviousMonthNo) + ' ' +
            Format(PreviousYearNo) + ' ' + '-' + ' ' + GetMonthName(PreviousMonthNo) + ' ' + Format(PreviousYearNo);
        FilteredContractRec."Owner Name" := ContractRec."Owner's Name";

        FilteredContractRec.Insert();

        // -----------------------------------------------
        // Insert grace period adjustment line (negative allocation) for missed days
        // Only if grace period dates overlap with the missed allocation period
        // -----------------------------------------------
        if ShouldInsertGraceLine then begin
            NewLineNo := GetNextLineNo();

            FilteredContractRec.Init();
            FilteredContractRec."Line No." := NewLineNo;
            FilteredContractRec."Header No." := Rec."No.";
            FilteredContractRec."Property Name" := ContractRec."Property Name";
            FilteredContractRec."Contract Id" := ContractRec."Contract ID";
            FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
            FilteredContractRec."Customer Name" := ContractRec."Customer Name";
            FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
            FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
            FilteredContractRec."Grace Days" := ContractRec."Grace Period";
            FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
            FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";
            FilteredContractRec.Description := 'Grace Period';

            if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
            else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
            else
                FilteredContractRec."Single Unit Names" := '';

            // Add Termination Date
            if TerminationDate = 0D then
                FilteredContractRec."Termination Date" := 0D
            else
                FilteredContractRec."Termination Date" := TerminationDate;

            if SuspensionRec.FindFirst() then begin
                FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
                FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
            end;

            FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
            FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
            FilteredContractRec."No Of Days" := MissedDays;
            FilteredContractRec."Per Month Rent" := -DifferencePerDayRent; // Negative value
            FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount";
            FilteredContractRec."Annual Amount" := GridAnnualAmount;
            FilteredContractRec."Total Value" := -GracePeriodAdjustmentValue; // Negative adjustment
            FilteredContractRec."Owner Share" := -GracePeriodAdjustmentValue; // Negative adjustment
            FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
            FilteredContractRec."Posting Month" := PreviousMonthNo;
            FilteredContractRec."Posting Year" := PreviousYearNo;
            FilteredContractRec."Posting Period" := GetMonthName(PreviousMonthNo) + ' ' +
                Format(PreviousYearNo) + ' ' + '-' + ' ' + GetMonthName(PreviousMonthNo) + ' ' + Format(PreviousYearNo);
            FilteredContractRec."Owner Name" := ContractRec."Owner's Name";
            FilteredContractRec.Insert();
        end;
    end;

    procedure FetchContractss()
    var
        // Record variables for different data sources
        FilterHeader: Record "Revenue Allocation Details";           // Header record
        ContractRec: Record "Tenancy Contract";                     // Main contract record
        FilteredContractRec: Record "Revenue Allocation SubGrid";    // Target allocation table
        SuspensionRec: Record SuspendReasonTable;                   // Suspension information
        FinalCalculationRec: Record "Final Calculation";            // Final calculation data

        // Rent type record variables
        SingleUnitRent: Record "TC Single Unit Rent SubPage";        // Single unit rent records
        MultiUnitRent: Record "TC Single LumAnnualAmnt SP";         // Multi unit rent records
        MergedSingleRent: Record "TC Merge SameSqure SubPage";      // Merged single rent records
        MergedMultiRent: Record "TC Merge DifferentSq SubPage";     // Merged multi rent records
        SpecialRent: Record "TC Merge LumAnnualAmount SP";          // Special rent records

        // Date and calculation variables
        SelectedMonthStart: Date;                                   // First day of selected month
        SelectedMonthEnd: Date;                                     // Last day of selected month
        MonthNo: Integer;                                           // Selected month number
        FinancialYear: Integer;                                     // Selected financial year
        LineNo: Integer;                                            // Line number for allocations
        TerminationDate: Date;                                      // Contract termination date
        SuspensionDate: Date;
        ShouldProcessContract: Boolean;                             // Flag to determine if contract should be processed
    begin
        // Clear any existing allocation data before processing
        ClearSubgridData();

        // Get month and year from current record
        MonthNo := Rec.Month;
        FinancialYear := Rec."Financial Year";

        // Calculate date range for the selected month
        SelectedMonthStart := DMY2Date(01, MonthNo, FinancialYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Filter contracts to include both Active and Terminated contracts
        ContractRec.SetFilter(ContractRec."Tenant Contract Status", '%1|%2|%3',
            ContractRec."Tenant Contract Status"::Active,
            ContractRec."Tenant Contract Status"::Terminated,
            ContractRec."Tenant Contract Status"::Suspended);

        if ContractRec.FindSet() then begin
            repeat
                // Flag to determine if contract should be processed
                TerminationDate := 0D;
                SuspensionDate := 0D;
                ShouldProcessContract := false;

                // Get termination date from Final Calculation table first
                FinalCalculationRec.Reset();
                FinalCalculationRec.SetRange("Contract ID", ContractRec."Contract ID");
                if FinalCalculationRec.FindFirst() then
                    TerminationDate := FinalCalculationRec."Termination Date"
                else
                    TerminationDate := 0D;

                // Get Suspension Start Date
                SuspensionRec.Reset();
                SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
                if SuspensionRec.FindFirst() then
                    SuspensionDate := SuspensionRec.DateEffective
                else
                    SuspensionDate := 0D;  // Explicitly set to 0D if not found

                // Check contract status and decide if it should be processed
                case ContractRec."Tenant Contract Status" of
                    ContractRec."Tenant Contract Status"::Active:
                        ShouldProcessContract := true;

                    ContractRec."Tenant Contract Status"::Terminated:
                        if (TerminationDate >= SelectedMonthStart) and (TerminationDate <= SelectedMonthEnd) then
                            ShouldProcessContract := true;

                    ContractRec."Tenant Contract Status"::Suspended:
                        // FIXED: Added null date check and improved logic
                        if (SuspensionDate <> 0D) and
                           (SuspensionDate >= SelectedMonthStart) and
                           (SuspensionDate <= SelectedMonthEnd) then
                            ShouldProcessContract := true;
                end;


                // Process contract only if it meets the criteria
                if ShouldProcessContract then begin
                    // PURPOSE: Process only contracts that overlap with selected month
                    // LOGIC: Contract start date <= month end AND contract end date >= month start
                    if ((ContractRec."Contract Start Date" <= SelectedMonthEnd) and
                        (ContractRec."Contract End Date" >= SelectedMonthStart)) then begin

                        // Handle missed allocation from previous month (if contract started mid-month)
                        HandleMissedAllocations(ContractRec, MonthNo, FinancialYear);

                        // Handle suspension recovery allocation (new functionality)
                        HandleSuspensionRecoveryAllocations(ContractRec, MonthNo, FinancialYear);

                        // Process Single Unit Rent records
                        SingleUnitRent.Reset();
                        SingleUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if SingleUnitRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Single Unit Rent record
                                InsertAllocationLines(
                                    ContractRec,
                                    SingleUnitRent."Start Date",
                                    SingleUnitRent."End Date",
                                    SingleUnitRent."Number of Days",
                                    SingleUnitRent."Per Day Rent",
                                    SingleUnitRent."Final Annual Amount",
                                    SingleUnitRent."Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until SingleUnitRent.Next() = 0;
                        end;

                        // Check Multi Unit Rent grid
                        MultiUnitRent.Reset();
                        MultiUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if MultiUnitRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Multi Unit Rent record
                                InsertAllocationLines(
                                    ContractRec,
                                    MultiUnitRent."SL_Start Date",
                                    MultiUnitRent."SL_End Date",
                                    MultiUnitRent."SL_Number of Days",
                                    MultiUnitRent."SL_Per Day Rent",
                                    MultiUnitRent."SL_Final Annual Amount",
                                    MultiUnitRent."SL_Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until MultiUnitRent.Next() = 0;
                        end;

                        // Check Merged Single Rent grid
                        MergedSingleRent.Reset();
                        MergedSingleRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if MergedSingleRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Merged Single Rent record
                                InsertAllocationLines(
                                    ContractRec,
                                    MergedSingleRent."MS_Start Date",
                                    MergedSingleRent."MS_End Date",
                                    MergedSingleRent."MS_Number of Days",
                                    MergedSingleRent."MS_Per Day Rent",
                                    MergedSingleRent."MS_Final Annual Amount",
                                    MergedSingleRent."MS_Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until MergedSingleRent.Next() = 0;
                        end;

                        // Check Merged Multi Rent grid
                        MergedMultiRent.Reset();
                        MergedMultiRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if MergedMultiRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Merged Multi Rent record
                                InsertAllocationLines(
                                    ContractRec,
                                    MergedMultiRent."MD_Start Date",
                                    MergedMultiRent."MD_End Date",
                                    MergedMultiRent."MD_Number of Days",
                                    MergedMultiRent."MD_Per Day Rent",
                                    MergedMultiRent."MD_Final Annual Amount",
                                    MergedMultiRent."MD_Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until MergedMultiRent.Next() = 0;
                        end;

                        // Check Special Rent grid
                        SpecialRent.Reset();
                        SpecialRent.SetRange("Contract ID", ContractRec."Contract ID");
                        if SpecialRent.FindSet() then begin
                            repeat
                                // Create allocation line for this Special Rent record
                                InsertAllocationLines(
                                    ContractRec,
                                    SpecialRent."ML_Start Date",
                                    SpecialRent."ML_End Date",
                                    SpecialRent."ML_Number of Days",
                                    SpecialRent."ML_Per Day Rent",
                                    SpecialRent."ML_Final Annual Amount",
                                    SpecialRent."ML_Final Annual Amount",
                                    TerminationDate,
                                    LineNo,  // Use sequential number
                                    MonthNo,
                                    FinancialYear);
                            // LineNo += 1;  // Increment by 1
                            until SpecialRent.Next() = 0;
                        end;
                    end;
                end;
            until ContractRec.Next() = 0;
        end;
        CalculateTotals();
    end;

    //---------------Handle Suspension Recovery Allocation--------------//
    procedure HandleSuspensionRecoveryAllocations(
    ContractRec: Record "Tenancy Contract";
    MonthNo: Integer;
    FinancialYear: Integer)
    var
        SuspensionRec: Record SuspendReasonTable;
        CurrentMonthStart: Date;
        CurrentMonthEnd: Date;
        SuspensionStartDate: Date;
        SuspensionEndDate: Date;
        RecoveryStartDate: Date;
        RecoveryEndDate: Date;
        SingleUnitRent: Record "TC Single Unit Rent SubPage";
        MultiUnitRent: Record "TC Single LumAnnualAmnt SP";
        MergedSingleRent: Record "TC Merge SameSqure SubPage";
        MergedMultiRent: Record "TC Merge DifferentSq SubPage";
        SpecialRent: Record "TC Merge LumAnnualAmount SP";
        FinalCalculationRec: Record "Final Calculation";
        TerminationDate: Date;
        LineNo: Integer;
    begin
        // Calculate current month date range
        CurrentMonthStart := DMY2Date(1, MonthNo, FinancialYear);
        CurrentMonthEnd := CALCDATE('<CM>', CurrentMonthStart);

        // Check if contract was suspended and is now active
        SuspensionRec.Reset();
        SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
        SuspensionRec.SetFilter(SuspensionEndDate, '<%1', CurrentMonthStart); // Suspension ended before current month

        if SuspensionRec.FindLast() then begin
            SuspensionStartDate := SuspensionRec.DateEffective;
            SuspensionEndDate := SuspensionRec.SuspensionEndDate;

            // Recovery period starts from suspension start date to suspension end date
            RecoveryStartDate := SuspensionStartDate;
            RecoveryEndDate := SuspensionEndDate;

            // Validate that suspension period is valid and ended
            if (SuspensionEndDate <> 0D) and (SuspensionEndDate < CurrentMonthStart) then begin

                // Retrieve Termination Date from Final Calculation
                FinalCalculationRec.Reset();
                FinalCalculationRec.SetRange("Contract ID", ContractRec."Contract ID");
                if FinalCalculationRec.FindFirst() then
                    TerminationDate := FinalCalculationRec."Termination Date"
                else
                    TerminationDate := 0D;

                // Process each rent type for suspension recovery allocation
                // Check Single Unit Rent grid
                SingleUnitRent.Reset();
                SingleUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
                if SingleUnitRent.FindSet() then begin
                    repeat
                        if (SingleUnitRent."Start Date" <= RecoveryEndDate) and (SingleUnitRent."End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLines(
                                ContractRec,
                                SingleUnitRent."Start Date",
                                SingleUnitRent."End Date",
                                SingleUnitRent."Number of Days",
                                SingleUnitRent."Per Day Rent",
                                SingleUnitRent."Final Annual Amount",
                                SingleUnitRent."Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Single Unit Rent Recovery');
                        end;
                    until SingleUnitRent.Next() = 0;
                end;

                // Check Multi Unit Rent grid
                MultiUnitRent.Reset();
                MultiUnitRent.SetRange("Contract ID", ContractRec."Contract ID");
                if MultiUnitRent.FindSet() then begin
                    repeat
                        if (MultiUnitRent."SL_Start Date" <= RecoveryEndDate) and (MultiUnitRent."SL_End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLines(
                                ContractRec,
                                MultiUnitRent."SL_Start Date",
                                MultiUnitRent."SL_End Date",
                                MultiUnitRent."SL_Number of Days",
                                MultiUnitRent."SL_Per Day Rent",
                                MultiUnitRent."SL_Final Annual Amount",
                                MultiUnitRent."SL_Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Multi Unit Rent Recovery');
                        end;
                    until MultiUnitRent.Next() = 0;
                end;

                // Check Merged Single Rent grid
                MergedSingleRent.Reset();
                MergedSingleRent.SetRange("Contract ID", ContractRec."Contract ID");
                if MergedSingleRent.FindSet() then begin
                    repeat
                        if (MergedSingleRent."MS_Start Date" <= RecoveryEndDate) and (MergedSingleRent."MS_End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLines(
                                ContractRec,
                                MergedSingleRent."MS_Start Date",
                                MergedSingleRent."MS_End Date",
                                MergedSingleRent."MS_Number of Days",
                                MergedSingleRent."MS_Per Day Rent",
                                MergedSingleRent."MS_Final Annual Amount",
                                MergedSingleRent."MS_Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Merged Single Rent Recovery');
                        end;
                    until MergedSingleRent.Next() = 0;
                end;

                // Check Merged Multi Rent grid
                MergedMultiRent.Reset();
                MergedMultiRent.SetRange("Contract ID", ContractRec."Contract ID");
                if MergedMultiRent.FindSet() then begin
                    repeat
                        if (MergedMultiRent."MD_Start Date" <= RecoveryEndDate) and (MergedMultiRent."MD_End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLines(
                                ContractRec,
                                MergedMultiRent."MD_Start Date",
                                MergedMultiRent."MD_End Date",
                                MergedMultiRent."MD_Number of Days",
                                MergedMultiRent."MD_Per Day Rent",
                                MergedMultiRent."MD_Final Annual Amount",
                                MergedMultiRent."MD_Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Merged Multi Rent Recovery');
                        end;
                    until MergedMultiRent.Next() = 0;
                end;

                // Check Special Rent grid
                SpecialRent.Reset();
                SpecialRent.SetRange("Contract ID", ContractRec."Contract ID");
                if SpecialRent.FindSet() then begin
                    repeat
                        if (SpecialRent."ML_Start Date" <= RecoveryEndDate) and (SpecialRent."ML_End Date" >= RecoveryStartDate) then begin
                            InsertSuspensionRecoveryLines(
                                ContractRec,
                                SpecialRent."ML_Start Date",
                                SpecialRent."ML_End Date",
                                SpecialRent."ML_Number of Days",
                                SpecialRent."ML_Per Day Rent",
                                SpecialRent."ML_Final Annual Amount",
                                SpecialRent."ML_Final Annual Amount",
                                TerminationDate,
                                LineNo,
                                MonthNo,
                                FinancialYear,
                                RecoveryStartDate,
                                RecoveryEndDate,
                                'Special Rent Recovery');
                        end;
                    until SpecialRent.Next() = 0;
                end;
            end;
        end;
    end;

    //---------------Insert Suspension Recovery Line--------------//
    procedure InsertSuspensionRecoveryLines(
    ContractRec: Record "Tenancy Contract";
    MultiYearStartDate: Date;
    MultiYearEndDate: Date;
    NoOfDays: Integer;
    PerDayRent: Decimal;
    TotalAnnualAmount: Decimal;
    OwnerShareAmount: Decimal;
    TerminationDate: Date;
    LineNo: Integer;
    MonthNo: Integer;
    FinancialYear: Integer;
    RecoveryStartDate: Date;
    RecoveryEndDate: Date;
    RecoveryType: Text)
    var
        FilteredContractRec: Record "Revenue Allocation SubGrid";
        SuspensionRec: Record SuspendReasonTable;
        CalculatedRecoveryDays: Integer;
        NewLineNo: Integer;
        GridAnnualAmount: Decimal;
        RecoveryAmount: Decimal;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        permonthrent: Decimal;
    begin
        // Get new line number
        NewLineNo := GetNextLineNo();

        // Use the annual amount from the grid record
        GridAnnualAmount := TotalAnnualAmount;

        // Calculate effective recovery period
        // Use the latest start date and earliest end date
        EffectiveStartDate := RecoveryStartDate;
        if MultiYearStartDate > EffectiveStartDate then
            EffectiveStartDate := MultiYearStartDate;

        EffectiveEndDate := RecoveryEndDate;
        if MultiYearEndDate < EffectiveEndDate then
            EffectiveEndDate := MultiYearEndDate;

        // Calculate recovery days
        if EffectiveStartDate <= EffectiveEndDate then
            CalculatedRecoveryDays := EffectiveEndDate - EffectiveStartDate + 1
        else
            CalculatedRecoveryDays := 0;

        // Only insert if there are days to recover
        if CalculatedRecoveryDays > 0 then begin
            // Calculate recovery amount
            RecoveryAmount := CalculatedRecoveryDays * PerDayRent;

            // Insert suspension recovery allocation line
            FilteredContractRec.Init();
            FilteredContractRec."Line No." := NewLineNo;
            FilteredContractRec."Header No." := Rec."No.";
            FilteredContractRec."Property Name" := ContractRec."Property Name";
            FilteredContractRec."Contract Id" := ContractRec."Contract ID";
            FilteredContractRec."Contract Tenure" := ContractRec."Contract Tenor";
            FilteredContractRec."Customer Name" := ContractRec."Customer Name";
            FilteredContractRec."Contract Start Date" := ContractRec."Contract Start Date";
            FilteredContractRec."Contract End Date" := ContractRec."Contract End Date";
            FilteredContractRec."Grace Days" := ContractRec."Grace Period";
            FilteredContractRec."Grace Start Date" := ContractRec."Grace Start Date";
            FilteredContractRec."Grace End Date" := ContractRec."Grace End Date";

            if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Single Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Unit Name"
            else if ContractRec."Praposal Type Selected" = ContractRec."Praposal Type Selected"::"Merge Unit" then
                FilteredContractRec."Single Unit Names" := ContractRec."Single Unit Name"
            else
                FilteredContractRec."Single Unit Names" := '';

            // Add Termination Date
            if TerminationDate = 0D then
                FilteredContractRec."Termination Date" := 0D
            else
                FilteredContractRec."Termination Date" := TerminationDate;

            // Add suspension information
            SuspensionRec.Reset();
            SuspensionRec.SetRange("Contract ID", ContractRec."Contract ID");
            if SuspensionRec.FindFirst() then begin
                FilteredContractRec."Suspension Start Date" := SuspensionRec.DateEffective;
                FilteredContractRec."Suspension End Date" := SuspensionRec.SuspensionEndDate;
            end;

            FilteredContractRec."Multi Year Start Date" := MultiYearStartDate;
            FilteredContractRec."Multi Year End Date" := MultiYearEndDate;
            FilteredContractRec."No Of Days" := CalculatedRecoveryDays;
            FilteredContractRec."Contract Amount" := ContractRec."Annual Rent Amount";
            FilteredContractRec."Annual Amount" := GridAnnualAmount;
            FilteredContractRec."Final Annual Amount" := TotalAnnualAmount;
            permonthrent := FilteredContractRec."Final Annual Amount" / 12;
            FilteredContractRec."Per Month Rent" := calculatepermonthrentss(permonthrent, CalculatedRecoveryDays, MonthNo, FinancialYear); // Use the per day rent passed from the grid
            FilteredContractRec."Posting Month" := MonthNo;
            FilteredContractRec."Posting Year" := FinancialYear;
            FilteredContractRec."Total Value" := FilteredContractRec."Per Month Rent";
            FilteredContractRec."Owner Share" := FilteredContractRec."Per Month Rent";
            FilteredContractRec.Description := 'Suspension';
            FilteredContractRec."Posting Period" := 'Suspension Recovery - ' + Format(MonthNo) + ' ' + Format(FinancialYear);
            FilteredContractRec."Owner Name" := ContractRec."Owner's Name";

            // Add a note to indicate this is suspension recovery
            // If you have a description field, uncomment below:
            // FilteredContractRec."Description" := RecoveryType + ' - Recovery Period: ' + 
            //     Format(EffectiveStartDate) + ' to ' + Format(EffectiveEndDate);
            FilteredContractRec.Insert();
        end;
    end;





    //////////////////////////////FIXED MONTH RENT///////////////////////////////////////////////////////////////

    var

        totalcontractAmountsss: Decimal;
        totalamountsss: Decimal;
        totalannualamountsss: Decimal;
        totalfinalannualamountsss: Decimal;

        totalcontractAmounts: Decimal;
        totalamounts: Decimal;

        totalcombinecontractAmounts: Decimal;
        totalcombineamounts: Decimal;

        TotalAnnualAmounts: Decimal;

        TotalFinalAnnualAmounts: Decimal;

    // trigger OnAfterGetRecord()
    // begin
    //     CurrPage."Revenue Recognition Item Details".Page.SetRIID(Rec."No.");
    //     CurrPage."Revenue Recognition Details".Page.SetRIID(Rec."No.");
    // end;


    trigger OnModifyRecord(): Boolean
    begin
        CurrPage."Revenue Recognition Item Details".Page.SetRIID(Rec."No.");
        CurrPage."Revenue Recognition Details".Page.SetRIID(Rec."No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage."Revenue Recognition Item Details".Page.SetRIID(Rec."No.");
        CurrPage."Revenue Recognition Details".Page.SetRIID(Rec."No.");
        CalculateAndStoreTotalRevenue();
    end;
}
