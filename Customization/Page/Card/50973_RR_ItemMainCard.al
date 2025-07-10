page 50973 "Revenue Recognition Item Sub"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Revenue Recognition Item";
    Caption = 'Revenue Item';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("RR_No."; Rec."RR_No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Item Type"; Rec."Item Type")
                {
                    ApplicationArea = All;
                    Caption = 'Item Type';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Entry No.';
                    Editable = false;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FetchRevenueDetails)
            {
                Caption = 'Revenue Allocation-Other Charges';
                ApplicationArea = All;
                Image = List;
                trigger OnAction()
                var
                    ConfirmFetch: Boolean;
                    revenueAllocation: Record "Revenue Allocation Details";
                begin
                    // Get the current Revenue Allocation record details
                    if not GetCurrentRevenueAllocation(RevenueAllocation) then begin
                        Message('Unable to get Revenue Allocation details. Please ensure you are on a valid record.');
                        exit;
                    end;

                    // Confirm before fetching details
                    ConfirmFetch := Confirm('Do you want to fetch revenue details for the selected Item Type(s) for %1 %2?',
                        false, Format(RevenueAllocation.Month), RevenueAllocation."Financial Year");

                    if ConfirmFetch then begin
                        // Call the fetch procedure with current allocation details
                        FetchContractDetails(RevenueAllocation);

                        // Show message about fetched details
                        Message('Revenue details have been fetched successfully.');
                    end;
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearSubgridData();
    end;

    // Get current Revenue Allocation record
    local procedure GetCurrentRevenueAllocation(var RevenueAllocation: Record "Revenue Allocation Details"): Boolean
    begin
        // Get the current RR_No from the record
        if Rec."RR_No." = 0 then
            exit(false);

        // Find the Revenue Allocation record using RR_No
        RevenueAllocation.Reset();
        RevenueAllocation.SetRange("No.", Rec."RR_No.");
        if RevenueAllocation.FindFirst() then
            exit(true);

        exit(false);
    end;

    procedure ClearSubgridData()
    var
        RevenueItemDetail: Record "Revenue Recognition Details";
    begin
        // Clear existing details for this Revenue Recognition record
        RevenueItemDetail.SetRange("RR_No.", Rec."RR_No.");
        RevenueItemDetail.DeleteAll(true);
    end;

    procedure FetchContractDetails(RevenueAllocation: Record "Revenue Allocation Details")
    var
        TenancyContract: Record "Tenancy Contract";
        RevenueStructure: Record "Revenue Structure";
        RevenueRecognitionDetails: Record "Revenue Recognition Details";
        SelectedItemTypes: List of [Text];
        ProcessedContractCount: Integer;
        ContractProcessed: Boolean;
        RevenueAllocationStartDate: Date;
        RevenueAllocationEndDate: Date;
    begin
        // Clear existing data
        ClearSubgridData();

        // Get selected Item Types for this Revenue Recognition Item
        GetSelectedItemTypes(SelectedItemTypes);

        // If no item types are selected, exit
        if SelectedItemTypes.Count = 0 then begin
            Message('Please select at least one Item Type.');
            exit;
        end;

        // Reset processed contract counter
        ProcessedContractCount := 0;

        // Calculate month start and end dates
        RevenueAllocationStartDate := DMY2Date(1, RevenueAllocation.Month, RevenueAllocation."Financial Year");
        RevenueAllocationEndDate := CalcDate('CM', RevenueAllocationStartDate);

        // Process active contracts directly from Revenue Structure
        if TenancyContract.FindSet() then begin
            repeat
                // Check if contract is active during the selected period
                if (TenancyContract."Contract Start Date" <= RevenueAllocationEndDate) and
                   (TenancyContract."Contract End Date" >= RevenueAllocationStartDate) then begin

                    // Reset flag for each contract
                    ContractProcessed := false;

                    // Get revenue structure details directly for this contract
                    RevenueStructure.Reset();
                    RevenueStructure.SetRange("Contract ID", TenancyContract."Contract ID");

                    // Filter by selected Item Types
                    RevenueStructure.SetFilter("Secondary Item Type", GetItemTypeFilter(SelectedItemTypes));

                    if RevenueStructure.FindSet() then begin
                        repeat
                            // Create Revenue Recognition Detail directly from Revenue Structure
                            CreateRevenueRecognitionDetailDirect(TenancyContract, RevenueStructure, RevenueAllocation);

                            // Mark contract as processed
                            ContractProcessed := true;
                        until RevenueStructure.Next() = 0;
                    end;

                    // Increment processed contract counter if at least one structure was found
                    if ContractProcessed then
                        ProcessedContractCount += 1;
                end;
            until TenancyContract.Next() = 0;
        end;

        // Refresh the page to show new details
        CurrPage.Update(false);

        // Show summary message
        Message(
            'Revenue Details Fetched Summary:\' +
            'Item Types: %1\' +
            'Processed Contracts: %2',
            GetItemTypeFilter(SelectedItemTypes),
            ProcessedContractCount
        );
    end;

    local procedure GetSelectedItemTypes(var pItemTypes: List of [Text])
    var
        RevenueRecognitionItem: Record "Revenue Recognition Item";
    begin
        // Set filter to get all selected Item Types
        RevenueRecognitionItem.SetRange("RR_No.", Rec."RR_No.");

        // Find all records for this Revenue Recognition
        if RevenueRecognitionItem.FindSet() then begin
            repeat
                // Only add non-empty Item Types
                if RevenueRecognitionItem."Item Type" <> '' then begin
                    // Check if Item Type is not already in the list
                    if not pItemTypes.Contains(RevenueRecognitionItem."Item Type") then
                        pItemTypes.Add(RevenueRecognitionItem."Item Type");
                end;
            until RevenueRecognitionItem.Next() = 0;
        end;
    end;

    local procedure GetItemTypeFilter(pItemTypes: List of [Text]): Text
    var
        FilterText: Text;
        ItemType: Text;
    begin
        // Build filter text
        foreach ItemType in pItemTypes do begin
            if FilterText = '' then
                FilterText := ItemType
            else
                FilterText += '|' + ItemType;
        end;

        exit(FilterText);
    end;

    procedure CalculateNoOfDays(
           pContractStartDate: Date;
           pContractEndDate: Date;
           pAllocationMonth: Integer;
           pAllocationYear: Integer;
           pTerminationDate: Date
       ): Integer
    var
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        NoOfDays: Integer;
        TerminationDay: Integer;
    begin
        // Start and end of the selected month
        SelectedMonthStart := DMY2Date(1, pAllocationMonth, pAllocationYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Special Termination case:
        if (pTerminationDate <> 0D) then begin
            if (pTerminationDate < pContractEndDate) and
            (Date2DMY(pTerminationDate, 2) = pAllocationMonth) and
            (Date2DMY(pTerminationDate, 3) = pAllocationYear) then begin
                TerminationDay := Date2DMY(pTerminationDate, 1); // e.g., 3
                // Message('%1 - %2', pTerminationDate, TerminationDay);
                exit(TerminationDay);
            end;
        end;

        // Return 0 if contract is outside of the selected month
        if (pContractStartDate > SelectedMonthEnd) or (pContractEndDate < SelectedMonthStart) then
            exit(0);

        // Determine the effective start date
        if pContractStartDate > SelectedMonthStart then
            EffectiveStartDate := pContractStartDate
        else
            EffectiveStartDate := SelectedMonthStart;

        // Determine the effective end date
        if pContractEndDate < SelectedMonthEnd then
            EffectiveEndDate := pContractEndDate
        else
            EffectiveEndDate := SelectedMonthEnd;

        // Calculate inclusive number of days
        NoOfDays := EffectiveEndDate - EffectiveStartDate + 1;

        exit(NoOfDays);
    end;

    // NEW: Calculate number of days for suspended period allocation
    local procedure CalculateSuspendedPeriodDays(
        pSuspensionStartDate: Date;
        pSuspensionEndDate: Date;
        pAllocationEndDate: Date
    ): Integer
    var
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        NoOfDays: Integer;
    begin
        // If no suspension dates, return 0
        if (pSuspensionStartDate = 0D) or (pSuspensionEndDate = 0D) then
            exit(0);

        // Effective start is the suspension start date
        EffectiveStartDate := pSuspensionStartDate;

        // Effective end is the minimum of suspension end date and allocation end date
        if pSuspensionEndDate < pAllocationEndDate then
            EffectiveEndDate := pSuspensionEndDate
        else
            EffectiveEndDate := pAllocationEndDate;

        // Calculate inclusive number of days
        if EffectiveEndDate >= EffectiveStartDate then
            NoOfDays := EffectiveEndDate - EffectiveStartDate + 1
        else
            NoOfDays := 0;

        exit(NoOfDays);
    end;

    // NEW: Check if contract has suspension to active scenario
    local procedure HasSuspensionToActiveScenario(
        pContractID: Integer;
        pAllocationStartDate: Date;
        pAllocationEndDate: Date;
        var pSuspensionStartDate: Date;
        var pSuspensionEndDate: Date
    ): Boolean
    var
        SuspendedReasonList: Record SuspendReasonTable;
    begin
        SuspendedReasonList.Reset();
        SuspendedReasonList.SetRange("Contract ID", pContractID);
        if SuspendedReasonList.FindFirst() then begin
            pSuspensionStartDate := SuspendedReasonList.DateEffective;
            pSuspensionEndDate := SuspendedReasonList.SuspensionEndDate;

            // Check if contract was suspended and then became active within the allocation period
            // Scenario: Contract was suspended, but suspension ended before or during allocation period
            if (pSuspensionStartDate <> 0D) and (pSuspensionEndDate <> 0D) then begin
                // Check if suspension ended before allocation end date
                // This means contract became active and we need to allocate for suspended period
                if (pSuspensionEndDate < pAllocationEndDate) and (pSuspensionStartDate <= pAllocationEndDate) then
                    exit(true);
            end;
        end;

        exit(false);
    end;

    // NEW: Function to check if contract is suspended in selected month/year
    local procedure IsContractSuspendedInPeriod(
        pContractID: Integer;
        pAllocationMonth: Integer;
        pAllocationYear: Integer;
        var pSuspensionDate: Date
    ): Boolean
    var
        SuspendedReasonList: Record SuspendReasonTable;
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
    begin
        // Calculate selected month start and end dates
        SelectedMonthStart := DMY2Date(1, pAllocationMonth, pAllocationYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Check if contract is suspended
        SuspendedReasonList.Reset();
        SuspendedReasonList.SetRange("Contract ID", pContractID);
        if SuspendedReasonList.FindFirst() then begin
            // Check if suspension date falls within selected month/year
            if (SuspendedReasonList.DateEffective >= SelectedMonthStart) and
               (SuspendedReasonList.DateEffective <= SelectedMonthEnd) then begin
                pSuspensionDate := SuspendedReasonList.DateEffective;
                exit(true);
            end;
        end;

        exit(false);
    end;

    // NEW: Calculate days for suspended contract (only till suspension date)
    local procedure CalculateSuspendedContractDays(
        pContractStartDate: Date;
        pContractEndDate: Date;
        pAllocationMonth: Integer;
        pAllocationYear: Integer;
        pSuspensionDate: Date
    ): Integer
    var
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        NoOfDays: Integer;
        SuspensionDay: Integer;
    begin
        // Start and end of the selected month
        SelectedMonthStart := DMY2Date(1, pAllocationMonth, pAllocationYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Return 0 if contract is outside of the selected month
        if (pContractStartDate > SelectedMonthEnd) or (pContractEndDate < SelectedMonthStart) then
            exit(0);

        // Determine the effective start date
        if pContractStartDate > SelectedMonthStart then
            EffectiveStartDate := pContractStartDate
        else
            EffectiveStartDate := SelectedMonthStart;

        // For suspended contracts, effective end date is the suspension date
        // (not the full month or contract end date)
        EffectiveEndDate := pSuspensionDate;

        // Make sure suspension date is not before the effective start
        if EffectiveEndDate < EffectiveStartDate then
            exit(0);

        // Calculate inclusive number of days till suspension date
        NoOfDays := EffectiveEndDate - EffectiveStartDate + 1;

        exit(NoOfDays);
    end;

    // MODIFIED: Update your existing CreateRevenueRecognitionDetailDirect procedure
    local procedure CreateRevenueRecognitionDetailDirect(
        pTenancyContract: Record "Tenancy Contract";
        pRevenueStructure: Record "Revenue Structure";
        pRevenueAllocation: Record "Revenue Allocation Details"
    )
    var
        RevenueRecognitionDetails: Record "Revenue Recognition Details";
        SuspendedReasonList: Record SuspendReasonTable;
        revenuestructuredetails: Record "Revenue Structure Subpage";
        PostingDate: Date;
        NextEntryNo: Integer;
        NoOfDays: Integer;
        PerDayAmount: Decimal;
        RevenueAllocationStartDate: Date;
        RevenueAllocationEndDate: Date;
        SuspensionStartDate: Date;
        SuspensionEndDate: Date;
        SuspendedPeriodDays: Integer;
        FinalCalculation: Record "Final Calculation";
        TerminationDate: Date;
        SuspensionDate: Date;
        IsContractSuspended: Boolean;
    begin
        // Calculate month start and end dates
        RevenueAllocationStartDate := DMY2Date(1, pRevenueAllocation.Month, pRevenueAllocation."Financial Year");
        RevenueAllocationEndDate := CalcDate('CM', RevenueAllocationStartDate);

        // Convert Posting Month + Year to Date (assume 1st of that month)
        PostingDate := DMY2Date(1, pRevenueAllocation.Month, pRevenueAllocation."Financial Year");

        // Get termination date for this contract
        FinalCalculation.Reset();
        FinalCalculation.SetRange("Contract ID", pTenancyContract."Contract ID");
        if FinalCalculation.FindFirst() then
            TerminationDate := FinalCalculation."Termination Date"
        else
            TerminationDate := 0D;

        // NEW: Check if contract is suspended in selected month/year
        IsContractSuspended := IsContractSuspendedInPeriod(
            pTenancyContract."Contract ID",
            pRevenueAllocation.Month,
            pRevenueAllocation."Financial Year",
            SuspensionDate
        );

        // Calculate number of days based on suspension status
        if IsContractSuspended then begin
            // For suspended contracts, calculate days only till suspension date
            NoOfDays := CalculateSuspendedContractDays(
                pTenancyContract."Contract Start Date",
                pTenancyContract."Contract End Date",
                pRevenueAllocation.Month,
                pRevenueAllocation."Financial Year",
                SuspensionDate
            );
        end else begin
            // For normal contracts, use existing logic
            NoOfDays := CalculateNoOfDays(
                pTenancyContract."Contract Start Date",
                pTenancyContract."Contract End Date",
                pRevenueAllocation.Month,
                pRevenueAllocation."Financial Year",
                TerminationDate
            );
        end;

        // Calculate per day amount from Revenue Structure
        if pRevenueStructure."Amount Including VAT" > 0 then begin
            PerDayAmount := pRevenueStructure."Amount Including VAT" / Date2DMY(RevenueAllocationEndDate, 1);
        end else
            PerDayAmount := 0;

        // Create revenue record only if there are days to allocate
        if NoOfDays > 0 then begin
            CreateRevenueRecord(
                pTenancyContract,
                pRevenueStructure,
                pRevenueAllocation,
                revenuestructuredetails,
                PostingDate,
                NoOfDays,
                PerDayAmount,
                IsContractSuspended // Pass suspension status
            );
        end;

        // Keep existing logic for suspension to active scenario
        if HasSuspensionToActiveScenario(
            pTenancyContract."Contract ID",
            RevenueAllocationStartDate,
            RevenueAllocationEndDate,
            SuspensionStartDate,
            SuspensionEndDate
        ) then begin
            SuspendedPeriodDays := CalculateSuspendedPeriodDays(
                SuspensionStartDate,
                SuspensionEndDate,
                RevenueAllocationEndDate
            );

            if SuspendedPeriodDays > 0 then begin
                CreateRevenueRecord(
                    pTenancyContract,
                    pRevenueStructure,
                    pRevenueAllocation,
                    revenuestructuredetails,
                    PostingDate,
                    SuspendedPeriodDays,
                    PerDayAmount,
                    true
                );
            end;
        end;
    end;

    // NEW: Common procedure to create revenue record
    local procedure CreateRevenueRecord(
        pTenancyContract: Record "Tenancy Contract";
        pRevenueStructure: Record "Revenue Structure";
        pRevenueAllocation: Record "Revenue Allocation Details";
        var revenuestructuredetails: Record "Revenue Structure Subpage";
        PostingDate: Date;
        NoOfDays: Integer;
        PerDayAmount: Decimal;
        IsSuspendedPeriodAllocation: Boolean
    )
    var
        RevenueRecognitionDetails: Record "Revenue Recognition Details";
        NextEntryNo: Integer;
        RecordDescription: Text;
        FinalCalculation: Record "Final Calculation";
        TerminationDate: Date;
        ActualNoOfDays: Integer;
        Yearlydays: Integer;
    begin
        // Get next entry number
        RevenueRecognitionDetails.Reset();
        if RevenueRecognitionDetails.FindLast() then
            NextEntryNo := RevenueRecognitionDetails."Entry No." + 1
        else
            NextEntryNo := 1;

        // Create new Revenue Recognition Detail record
        RevenueRecognitionDetails.Init();
        RevenueRecognitionDetails."Entry No." := NextEntryNo;
        RevenueRecognitionDetails."RR_No." := Rec."RR_No.";

        // Copy contract details
        RevenueRecognitionDetails."Contract Id" := pTenancyContract."Contract ID";
        RevenueRecognitionDetails."Property Name" := pTenancyContract."Property Name";
        RevenueRecognitionDetails."Customer Name" := pTenancyContract."Customer Name";
        RevenueRecognitionDetails."Contract Start Date" := pTenancyContract."Contract Start Date";
        RevenueRecognitionDetails."Contract End Date" := pTenancyContract."Contract End Date";
        RevenueRecognitionDetails."Contract Amount" := pRevenueStructure."Amount Including VAT";
        RevenueRecognitionDetails."Owner Name" := pTenancyContract."Owner's Name";
        RevenueRecognitionDetails."Contract Tenure" := pTenancyContract."Contract Tenor";
        RevenueRecognitionDetails."Grace Days" := pTenancyContract."Grace Period";
        RevenueRecognitionDetails."Grace Start Date" := pTenancyContract."Grace Start Date";
        RevenueRecognitionDetails."Grace End Date" := pTenancyContract."Grace End Date";
        if pTenancyContract."Praposal Type Selected" = pTenancyContract."Praposal Type Selected"::"Single Unit" then
            RevenueRecognitionDetails."Single Unit Names" := pTenancyContract."Unit Name"
        else if pTenancyContract."Praposal Type Selected" = pTenancyContract."Praposal Type Selected"::"Merge Unit" then
            RevenueRecognitionDetails."Single Unit Names" := pTenancyContract."Single Unit Name"
        else
            RevenueRecognitionDetails."Single Unit Names" := '';

        // Add allocation period details
        RevenueRecognitionDetails."Posting Month" := pRevenueAllocation.Month;
        RevenueRecognitionDetails."Posting Year" := pRevenueAllocation."Financial Year";

        // NEW: Add description to differentiate regular vs suspended period allocation
        if IsSuspendedPeriodAllocation then
            RevenueRecognitionDetails."Posting Period" :=
                FORMAT(pRevenueAllocation.Month) + ' ' +
                FORMAT(pRevenueAllocation."Financial Year")
        else
            RevenueRecognitionDetails."Posting Period" :=
                FORMAT(pRevenueAllocation.Month) + ' ' +
                FORMAT(pRevenueAllocation."Financial Year");

        // Get termination date from Final Calculation by Contract ID match
        GetTerminationDate(pTenancyContract."Contract ID", RevenueRecognitionDetails);

        // IMPORTANT: For suspension scenarios, use the passed NoOfDays directly
        // For regular scenarios, recalculate using the standard function
        if IsSuspendedPeriodAllocation then begin
            // Use the suspension-specific calculation result
            ActualNoOfDays := NoOfDays;
        end else begin
            // Use the standard calculation for regular allocation
            ActualNoOfDays := CalculateNoOfDays(
                pTenancyContract."Contract Start Date",
                pTenancyContract."Contract End Date",
                pRevenueAllocation.Month,
                pRevenueAllocation."Financial Year",
                RevenueRecognitionDetails."Termination Date"
            );
        end;
        RevenueRecognitionDetails."No Of Days" := ActualNoOfDays;

        // Get suspension details from Suspended Reason List by Contract ID match
        GetSuspensionDetails(pTenancyContract."Contract ID", RevenueRecognitionDetails);

        revenuestructuredetails.Reset();
        revenuestructuredetails.SetRange("Contract ID", RevenueRecognitionDetails."Contract ID");
        revenuestructuredetails.SetRange("Secondary Item Type", pRevenueStructure."Secondary Item Type");
        if revenuestructuredetails.FindSet() then begin
            repeat
                if (revenuestructuredetails."Period Start Date" <= PostingDate) and
                   (revenuestructuredetails."Period End Date" >= PostingDate) then begin
                    RevenueRecognitionDetails."Multi Year Start Date" := revenuestructuredetails."Period Start Date";
                    RevenueRecognitionDetails."Multi Year End Date" := revenuestructuredetails."Period End Date";
                    RevenueRecognitionDetails."Annual Amount" := revenuestructuredetails."Final Annual Amount" + revenuestructuredetails."Final Annual Amount" * 5 / 100;
                    RevenueRecognitionDetails."Final Annual Amount" := RevenueRecognitionDetails."Annual Amount";
                    RevenueRecognitionDetails."Item Type" := revenuestructuredetails."Secondary Item Type";
                end;
            until revenuestructuredetails.Next() = 0;
        end;

        Yearlydays := RevenueRecognitionDetails."Multi Year End Date" - RevenueRecognitionDetails."Multi Year Start Date" + 1;
        RevenueRecognitionDetails."Per Day Rent" := RevenueRecognitionDetails."Annual Amount" / Yearlydays;
        RevenueRecognitionDetails."Total Value" := RevenueRecognitionDetails."No Of Days" * RevenueRecognitionDetails."Per Day Rent";
        RevenueRecognitionDetails."Owner Share" := RevenueRecognitionDetails."Total Value";

        // Insert the record
        RevenueRecognitionDetails.Insert(true);
    end;

    // Get termination date from Final Calculation table
    local procedure GetTerminationDate(ContractID: Integer; var RevenueRecognitionDetails: Record "Revenue Recognition Details")
    var
        FinalCalculation: Record "Final Calculation";
    begin
        FinalCalculation.Reset();
        FinalCalculation.SetRange("Contract ID", ContractID);
        if FinalCalculation.FindFirst() then
            RevenueRecognitionDetails."Termination Date" := FinalCalculation."Termination Date";
    end;

    // Get suspension details from Suspended Reason table
    local procedure GetSuspensionDetails(ContractID: Integer; var RevenueRecognitionDetails: Record "Revenue Recognition Details")
    var
        SuspendedReasonList: Record SuspendReasonTable;
    begin
        SuspendedReasonList.Reset();
        SuspendedReasonList.SetRange("Contract ID", ContractID);
        if SuspendedReasonList.FindFirst() then begin
            RevenueRecognitionDetails."Suspension Start Date" := SuspendedReasonList.DateEffective;
            RevenueRecognitionDetails."Suspension End Date" := SuspendedReasonList.SuspensionEndDate;
        end;
    end;

    var
        RRID: Integer;

    procedure SetRIID(pRRID: Integer)
    begin
        RRID := pRRID;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."RR_No." := RRID;
        exit(true);
    end;
}
