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
                    companydata: Record "testData";
                begin
                    if companydata.FindSet() then begin
                        if companydata."Revenue Methods" = companydata."Revenue Methods"::"Per Day Rent" then begin
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
                        end else begin
                            if not GetCurrentRevenueAllocation(RevenueAllocation) then begin
                                Message('Unable to get Revenue Allocation details. Please ensure you are on a valid record.');
                                exit;
                            end;

                            // Confirm before fetching details
                            ConfirmFetch := Confirm('Do you want to fetch revenue details for the selected Item Type(s) for %1 %2?',
                                false, Format(RevenueAllocation.Month), RevenueAllocation."Financial Year");

                            if ConfirmFetch then begin
                                // Call the fetch procedure with current allocation details
                                FetchContractDetailss(RevenueAllocation);

                                // Show message about fetched details
                                Message('Revenue details have been fetched successfully.');
                            end;
                        end;
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
                // NEW: Check if contract should be processed based on status and dates
                if ShouldProcessContract(TenancyContract, RevenueAllocation.Month, RevenueAllocation."Financial Year") then begin
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
                end;
            until TenancyContract.Next() = 0;
        end;

        // Process MISSED REVENUE for contracts that started in previous month
        ProcessAllMissedRevenueAllocations(RevenueAllocation);

        // Refresh the page to show new details
        CurrPage.Update(false);

        // Show summary message
        Message(
            'Revenue Details Fetched Summary:\' +
            'Item Types: %1\' +
            'Contracts Processed (Active/Suspended/Terminated): %2',
            GetItemTypeFilter(SelectedItemTypes),
            ProcessedContractCount
        );
    end;

    // Enhanced procedure to process ALL missed revenue allocations dynamically
    local procedure ProcessAllMissedRevenueAllocations(pCurrentAllocation: Record "Revenue Allocation Details")
    var
        TenancyContract: Record "Tenancy Contract";
        RevenueStructure: Record "Revenue Structure";
        PreviousAllocationMonth: Integer;
        PreviousAllocationYear: Integer;
        PreviousAllocationStartDate: Date;
        PreviousAllocationEndDate: Date;
        TempRevenueAllocation: Record "Revenue Allocation Details";
        SelectedItemTypes: List of [Text];
        MissedContractCount: Integer;
    begin
        // Get selected item types
        GetSelectedItemTypes(SelectedItemTypes);

        // Calculate previous month dynamically
        PreviousAllocationMonth := pCurrentAllocation.Month - 1;
        PreviousAllocationYear := pCurrentAllocation."Financial Year";

        // Handle year transition
        if PreviousAllocationMonth = 0 then begin
            PreviousAllocationMonth := 12;
            PreviousAllocationYear := PreviousAllocationYear - 1;
        end;

        // Calculate dates for the previous month
        PreviousAllocationStartDate := DMY2Date(1, PreviousAllocationMonth, PreviousAllocationYear);
        PreviousAllocationEndDate := CalcDate('CM', PreviousAllocationStartDate);

        // Initialize missed contract counter
        MissedContractCount := 0;

        // Find ALL contracts that started in previous month (date 2-31)
        TenancyContract.Reset();
        TenancyContract.SetFilter("Contract Start Date", '%1..%2',
            DMY2Date(2, PreviousAllocationMonth, PreviousAllocationYear),
            PreviousAllocationEndDate);

        if TenancyContract.FindSet() then begin
            repeat
                // Additional check: Contract should be active during previous month
                if (TenancyContract."Contract Start Date" <= PreviousAllocationEndDate) and
                   (TenancyContract."Contract End Date" >= PreviousAllocationStartDate) then begin

                    // Check if this contract was missed in previous allocation
                    if IsMissedRevenueAllocationForContract(
                        TenancyContract."Contract ID",
                        PreviousAllocationMonth,
                        PreviousAllocationYear,
                        pCurrentAllocation.Month,
                        pCurrentAllocation."Financial Year"
                    ) then begin

                        // Get revenue structure for this contract
                        RevenueStructure.Reset();
                        RevenueStructure.SetRange("Contract ID", TenancyContract."Contract ID");
                        RevenueStructure.SetFilter("Secondary Item Type", GetItemTypeFilter(SelectedItemTypes));

                        if RevenueStructure.FindSet() then begin
                            // Create temporary allocation record for missed month
                            TempRevenueAllocation := pCurrentAllocation;
                            TempRevenueAllocation.Month := PreviousAllocationMonth;
                            TempRevenueAllocation."Financial Year" := PreviousAllocationYear;

                            // Create missed revenue allocation for this contract
                            CreateMissedRevenueAllocationForContract(
                                TenancyContract,
                                RevenueStructure,
                                TempRevenueAllocation
                            );

                            MissedContractCount += 1;
                        end;
                    end;
                end;
            until TenancyContract.Next() = 0;
        end;

        // Optional: Show message about missed contracts processed
        if MissedContractCount > 0 then
            Message('Processed %1 missed revenue allocations for previous month (%2/%3)',
                MissedContractCount, PreviousAllocationMonth, PreviousAllocationYear);
    end;

    // Enhanced check for missed revenue allocation - more dynamic
    local procedure IsMissedRevenueAllocationForContract(
        ContractID: Integer;
        CheckMonth: Integer;
        CheckYear: Integer;
        currentMonth: Integer;
        currentYear: Integer
    ): Boolean
    var
        ExistingRevenue: Record "Revenue Recognition Details";
        RegularAllocationExists: Boolean;
        MissedAllocationExists: Boolean;
    begin
        // Check if regular revenue was already allocated for this contract in this month
        ExistingRevenue.Reset();
        ExistingRevenue.SetRange("Contract Id", ContractID);
        ExistingRevenue.SetRange("Posting Month", currentMonth);
        ExistingRevenue.SetRange("Posting Year", currentYear);
        ExistingRevenue.SetFilter("Posting Period", '<>%1', 'MISSED*'); // Exclude missed allocations

        RegularAllocationExists := not ExistingRevenue.IsEmpty;

        // Check if missed allocation already exists for this contract
        ExistingRevenue.Reset();
        ExistingRevenue.SetRange("Contract Id", ContractID);
        ExistingRevenue.SetRange("Posting Month", CheckMonth);
        ExistingRevenue.SetRange("Posting Year", CheckYear);
        ExistingRevenue.SetFilter("Posting Period", '%1', 'MISSED*'); // Only missed allocations

        MissedAllocationExists := not ExistingRevenue.IsEmpty;

        // Return true if no regular allocation exists AND no missed allocation exists
        exit(RegularAllocationExists and not MissedAllocationExists);
    end;

    // Create missed revenue allocation for a specific contract
    local procedure CreateMissedRevenueAllocationForContract(
        pTenancyContract: Record "Tenancy Contract";
        pRevenueStructure: Record "Revenue Structure";
        pMissedAllocation: Record "Revenue Allocation Details"
    )
    var
        RevenueStructureSubpage: Record "Revenue Structure Subpage";
        SelectedItemTypes: List of [Text];
        ItemType: Text;
        ProcessedItemTypes: Integer;
    begin
        // Get selected item types
        GetSelectedItemTypes(SelectedItemTypes);

        ProcessedItemTypes := 0;

        // Process each selected item type for this contract
        foreach ItemType in SelectedItemTypes do begin
            // Get revenue structure subpage for this item type
            RevenueStructureSubpage.Reset();
            RevenueStructureSubpage.SetRange("Contract ID", pTenancyContract."Contract ID");
            RevenueStructureSubpage.SetRange("Secondary Item Type", ItemType);

            if RevenueStructureSubpage.FindFirst() then begin
                // Create missed revenue allocation record
                CreateSingleMissedRevenueAllocation(
                    pTenancyContract,
                    RevenueStructureSubpage,
                    pMissedAllocation,
                    ItemType
                );

                ProcessedItemTypes += 1;
            end;
        end;
    end;

    // Enhanced missed revenue allocation creation with better contract detection
    local procedure CreateSingleMissedRevenueAllocation(
        pTenancyContract: Record "Tenancy Contract";
        pRevenueStructureSubpage: Record "Revenue Structure Subpage";
        pMissedAllocation: Record "Revenue Allocation Details";
        pItemType: Text
    )
    var
        RevenueRecognitionDetails: Record "Revenue Recognition Details";
        PostingDate: Date;
        NextEntryNo: Integer;
        NoOfDays: Integer;
        MissedAllocationStartDate: Date;
        MissedAllocationEndDate: Date;
        FinalCalculation: Record "Final Calculation";
        TerminationDate: Date;
        SuspensionDate: Date;
        IsContractSuspended: Boolean;
        Yearlydays: Integer;
        ContractStartInMonth: Integer;
        ContractStartDay: Integer;
    begin
        // Calculate missed month start and end dates
        MissedAllocationStartDate := DMY2Date(1, pMissedAllocation.Month, pMissedAllocation."Financial Year");
        MissedAllocationEndDate := CalcDate('CM', MissedAllocationStartDate);

        // Get contract start day to verify it's in range 2-31
        ContractStartDay := Date2DMY(pTenancyContract."Contract Start Date", 1);
        ContractStartInMonth := Date2DMY(pTenancyContract."Contract Start Date", 2);

        // Only process if contract started on day 2-31 of the previous month
        if (ContractStartInMonth = pMissedAllocation.Month) and (ContractStartDay >= 2) then begin

            // Convert Posting Month + Year to Date
            PostingDate := DMY2Date(1, pMissedAllocation.Month, pMissedAllocation."Financial Year");

            // Get termination date for this contract
            FinalCalculation.Reset();
            FinalCalculation.SetRange("Contract ID", pTenancyContract."Contract ID");
            if FinalCalculation.FindFirst() then
                TerminationDate := FinalCalculation."Termination Date"
            else
                TerminationDate := 0D;

            // Check if contract was suspended in the missed month
            IsContractSuspended := IsContractSuspendedInPeriod(
                pTenancyContract."Contract ID",
                pMissedAllocation.Month,
                pMissedAllocation."Financial Year",
                SuspensionDate
            );

            // Calculate number of days for missed allocation
            NoOfDays := CalculatePerfectNoOfDays(
                pTenancyContract."Contract Start Date",
                pTenancyContract."Contract End Date",
                pMissedAllocation.Month,
                pMissedAllocation."Financial Year",
                TerminationDate,
                IsContractSuspended,
                SuspensionDate
            );

            // Create missed revenue record only if there are days to allocate
            if NoOfDays > 0 then begin
                // Get next entry number
                RevenueRecognitionDetails.Reset();
                if RevenueRecognitionDetails.FindLast() then
                    NextEntryNo := RevenueRecognitionDetails."Entry No." + 1
                else
                    NextEntryNo := 1;

                // Create new Revenue Recognition Detail record for missed allocation
                RevenueRecognitionDetails.Init();
                RevenueRecognitionDetails."Entry No." := NextEntryNo;
                RevenueRecognitionDetails."RR_No." := Rec."RR_No.";

                // Copy contract details
                RevenueRecognitionDetails."Contract Id" := pTenancyContract."Contract ID";
                RevenueRecognitionDetails."Property Name" := pTenancyContract."Property Name";
                RevenueRecognitionDetails."Customer Name" := pTenancyContract."Customer Name";
                RevenueRecognitionDetails."Contract Start Date" := pTenancyContract."Contract Start Date";
                RevenueRecognitionDetails."Contract End Date" := pTenancyContract."Contract End Date";
                RevenueRecognitionDetails."Owner Name" := pTenancyContract."Owner's Name";
                RevenueRecognitionDetails."Contract Tenure" := pTenancyContract."Contract Tenor";
                RevenueRecognitionDetails."Grace Days" := pTenancyContract."Grace Period";
                RevenueRecognitionDetails."Grace Start Date" := pTenancyContract."Grace Start Date";
                RevenueRecognitionDetails."Grace End Date" := pTenancyContract."Grace End Date";

                // Set unit names based on proposal type
                if pTenancyContract."Praposal Type Selected" = pTenancyContract."Praposal Type Selected"::"Single Unit" then
                    RevenueRecognitionDetails."Single Unit Names" := pTenancyContract."Unit Name"
                else if pTenancyContract."Praposal Type Selected" = pTenancyContract."Praposal Type Selected"::"Merge Unit" then
                    RevenueRecognitionDetails."Single Unit Names" := pTenancyContract."Single Unit Name"
                else
                    RevenueRecognitionDetails."Single Unit Names" := '';

                // Add missed allocation period details
                RevenueRecognitionDetails."Posting Month" := pMissedAllocation.Month;
                RevenueRecognitionDetails."Posting Year" := pMissedAllocation."Financial Year";

                // Mark as missed revenue allocation with contract start date info
                RevenueRecognitionDetails."Posting Period" :=
                    'MISSED: ' + FORMAT(pMissedAllocation.Month) + '/' + FORMAT(pMissedAllocation."Financial Year") +
                    ' (Started: ' + FORMAT(pTenancyContract."Contract Start Date") + ')';

                // Set termination date and number of days
                RevenueRecognitionDetails."Termination Date" := TerminationDate;
                RevenueRecognitionDetails."No Of Days" := NoOfDays;

                // Get suspension details
                GetSuspensionDetails(pTenancyContract."Contract ID", RevenueRecognitionDetails);

                // Set revenue structure details from subpage
                RevenueRecognitionDetails."Multi Year Start Date" := pRevenueStructureSubpage."Period Start Date";
                RevenueRecognitionDetails."Multi Year End Date" := pRevenueStructureSubpage."Period End Date";
                RevenueRecognitionDetails."Annual Amount" := pRevenueStructureSubpage."Final Annual Amount" + pRevenueStructureSubpage."Final Annual Amount" * 5 / 100;
                RevenueRecognitionDetails."Final Annual Amount" := RevenueRecognitionDetails."Annual Amount";
                RevenueRecognitionDetails."Item Type" := pItemType;
                RevenueRecognitionDetails."Contract Amount" := pRevenueStructureSubpage."Final Annual Amount";

                // Calculate amounts
                Yearlydays := RevenueRecognitionDetails."Multi Year End Date" - RevenueRecognitionDetails."Multi Year Start Date" + 1;
                if Yearlydays > 0 then
                    RevenueRecognitionDetails."Per Day Rent" := RevenueRecognitionDetails."Annual Amount" / Yearlydays
                else
                    RevenueRecognitionDetails."Per Day Rent" := 0;

                RevenueRecognitionDetails."Total Value" := RevenueRecognitionDetails."No Of Days" * RevenueRecognitionDetails."Per Day Rent";
                RevenueRecognitionDetails."Owner Share" := RevenueRecognitionDetails."Total Value";

                // Insert the missed revenue record
                RevenueRecognitionDetails.Insert(true);
            end;
        end;
    end;

    // Perfect calculation of number of days - enhanced for missed allocations
    local procedure CalculatePerfectNoOfDays(
        ContractStartDate: Date;
        ContractEndDate: Date;
        ProcessMonth: Integer;
        ProcessYear: Integer;
        TerminationDate: Date;
        IsContractSuspended: Boolean;
        SuspensionDate: Date
    ): Integer
    var
        MonthStartDate: Date;
        MonthEndDate: Date;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        NoOfDays: Integer;
    begin
        // Calculate month boundaries
        MonthStartDate := DMY2Date(1, ProcessMonth, ProcessYear);
        MonthEndDate := CalcDate('CM', MonthStartDate);

        // For missed allocations, use the actual contract start date if it's within the month
        if (ContractStartDate >= MonthStartDate) and (ContractStartDate <= MonthEndDate) then
            EffectiveStartDate := ContractStartDate
        else
            EffectiveStartDate := MonthStartDate;

        // Determine effective end date (earlier of contract end, month end, or termination date)
        EffectiveEndDate := MonthEndDate;

        if ContractEndDate < EffectiveEndDate then
            EffectiveEndDate := ContractEndDate;

        if (TerminationDate <> 0D) and (TerminationDate < EffectiveEndDate) then
            EffectiveEndDate := TerminationDate;

        // Handle suspension
        if IsContractSuspended and (SuspensionDate <> 0D) and (SuspensionDate < EffectiveEndDate) then
            EffectiveEndDate := SuspensionDate;

        // Calculate number of days
        if EffectiveEndDate >= EffectiveStartDate then
            NoOfDays := EffectiveEndDate - EffectiveStartDate + 1
        else
            NoOfDays := 0;

        exit(NoOfDays);
    end;



    // UPDATED: Function to check if contract should be processed
    local procedure ShouldProcessContract(pTenancyContract: Record "Tenancy Contract"; pAllocationMonth: Integer; pAllocationYear: Integer): Boolean
    begin
        // 1. If Active - Always process
        if pTenancyContract."Tenant Contract Status" = pTenancyContract."Tenant Contract Status"::Active then
            exit(true);

        // 2. If Suspended - Check if suspension date falls in selected month/year
        if pTenancyContract."Tenant Contract Status" = pTenancyContract."Tenant Contract Status"::Suspended then begin
            if HasSuspensionInSelectedPeriod(pTenancyContract."Contract ID", pAllocationMonth, pAllocationYear) then
                exit(true);
        end;

        // 3. If Terminated - Check if termination date falls in selected month/year
        if pTenancyContract."Tenant Contract Status" = pTenancyContract."Tenant Contract Status"::Terminated then begin
            if HasTerminationInSelectedPeriod(pTenancyContract."Contract ID", pAllocationMonth, pAllocationYear) then
                exit(true);
        end;

        // Default: Don't process
        exit(false);
    end;

    // NEW: Check if suspension date falls in selected month/year
    local procedure HasSuspensionInSelectedPeriod(pContractID: Integer; pAllocationMonth: Integer; pAllocationYear: Integer): Boolean
    var
        SuspendedReasonList: Record SuspendReasonTable;
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
    begin
        // Calculate selected month start and end dates
        SelectedMonthStart := DMY2Date(1, pAllocationMonth, pAllocationYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Check if suspension date falls within selected period
        SuspendedReasonList.Reset();
        SuspendedReasonList.SetRange("Contract ID", pContractID);
        if SuspendedReasonList.FindFirst() then begin
            if (SuspendedReasonList.DateEffective >= SelectedMonthStart) and
               (SuspendedReasonList.DateEffective <= SelectedMonthEnd) then
                exit(true);
        end;

        exit(false);
    end;

    // NEW: Check if termination date falls in selected month/year
    local procedure HasTerminationInSelectedPeriod(pContractID: Integer; pAllocationMonth: Integer; pAllocationYear: Integer): Boolean
    var
        FinalCalculation: Record "Final Calculation";
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
    begin
        // Calculate selected month start and end dates
        SelectedMonthStart := DMY2Date(1, pAllocationMonth, pAllocationYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Check if termination date falls within selected period
        FinalCalculation.Reset();
        FinalCalculation.SetRange("Contract ID", pContractID);
        if FinalCalculation.FindFirst() then begin
            if (FinalCalculation."Termination Date" <> 0D) and
               (FinalCalculation."Termination Date" >= SelectedMonthStart) and
               (FinalCalculation."Termination Date" <= SelectedMonthEnd) then
                exit(true);
        end;

        exit(false);
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
            if (pSuspensionStartDate <> 0D) and (pSuspensionEndDate <> 0D) then begin
                // Check if suspension ended before allocation end date
                if (pSuspensionEndDate < pAllocationEndDate) and (pSuspensionStartDate <= pAllocationEndDate) then
                    exit(true);
            end;
        end;

        exit(false);
    end;

    // Alternative approach: If you want to check active status at field level
    local procedure IsContractActiveByStatus(ContractID: Integer): Boolean
    var
        TenancyContract: Record "Tenancy Contract";
    begin
        TenancyContract.Reset();
        TenancyContract.SetRange("Contract ID", ContractID);
        if TenancyContract.FindFirst() then begin
            // Adjust field name based on your table structure
            if TenancyContract."Tenant Contract Status" = TenancyContract."Tenant Contract Status"::Active then
                exit(true);
            // OR
            // if TenancyContract."Contract Status" = 'Active' then
            //     exit(true);
        end;
        exit(false);
    end;

    // NEW: Function to check if contract is suspended in selected month/year
    // MODIFIED: IsContractSuspendedInPeriod - Remove duplicate status check
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















    ///////////////////////////////////////////////////////FIXEDMONTHRENT////////////////////////////////////////////////////////////



    procedure FetchContractDetailss(RevenueAllocation: Record "Revenue Allocation Details")
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
        GetSelectedItemTypess(SelectedItemTypes);

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
                // NEW: Check if contract should be processed based on status and dates
                if ShouldProcessContracts(TenancyContract, RevenueAllocation.Month, RevenueAllocation."Financial Year") then begin
                    // Check if contract is active during the selected period
                    if (TenancyContract."Contract Start Date" <= RevenueAllocationEndDate) and
                       (TenancyContract."Contract End Date" >= RevenueAllocationStartDate) then begin

                        // Reset flag for each contract
                        ContractProcessed := false;

                        // Get revenue structure details directly for this contract
                        RevenueStructure.Reset();
                        RevenueStructure.SetRange("Contract ID", TenancyContract."Contract ID");

                        // Filter by selected Item Types
                        RevenueStructure.SetFilter("Secondary Item Type", GetItemTypeFilters(SelectedItemTypes));

                        if RevenueStructure.FindSet() then begin
                            repeat
                                // Create Revenue Recognition Detail directly from Revenue Structure
                                CreateRevenueRecognitionDetailDirects(TenancyContract, RevenueStructure, RevenueAllocation);

                                // Mark contract as processed
                                ContractProcessed := true;
                            until RevenueStructure.Next() = 0;
                        end;

                        // Increment processed contract counter if at least one structure was found
                        if ContractProcessed then
                            ProcessedContractCount += 1;
                    end;
                end;
            until TenancyContract.Next() = 0;
        end;

        // Process MISSED REVENUE for contracts that started in previous month
        ProcessAllMissedRevenueAllocationss(RevenueAllocation);

        // Refresh the page to show new details
        CurrPage.Update(false);

        // Show summary message
        // Message(
        //     'Revenue Details Fetched Summary:\' +
        //     'Item Types: %1\' +
        //     'Processed Contracts: %2',
        //     GetItemTypeFilters(SelectedItemTypes),
        //     ProcessedContractCount
        // );
    end;

    // Enhanced procedure to process ALL missed revenue allocations dynamically
    local procedure ProcessAllMissedRevenueAllocationss(pCurrentAllocation: Record "Revenue Allocation Details")
    var
        TenancyContract: Record "Tenancy Contract";
        RevenueStructure: Record "Revenue Structure";
        PreviousAllocationMonth: Integer;
        PreviousAllocationYear: Integer;
        PreviousAllocationStartDate: Date;
        PreviousAllocationEndDate: Date;
        TempRevenueAllocation: Record "Revenue Allocation Details";
        SelectedItemTypes: List of [Text];
        MissedContractCount: Integer;
    begin
        // Get selected item types
        GetSelectedItemTypess(SelectedItemTypes);

        // Calculate previous month dynamically
        PreviousAllocationMonth := pCurrentAllocation.Month - 1;
        PreviousAllocationYear := pCurrentAllocation."Financial Year";

        // Handle year transition
        if PreviousAllocationMonth = 0 then begin
            PreviousAllocationMonth := 12;
            PreviousAllocationYear := PreviousAllocationYear - 1;
        end;

        // Calculate dates for the previous month
        PreviousAllocationStartDate := DMY2Date(1, PreviousAllocationMonth, PreviousAllocationYear);
        PreviousAllocationEndDate := CalcDate('CM', PreviousAllocationStartDate);

        // Initialize missed contract counter
        MissedContractCount := 0;

        // Find ALL contracts that started in previous month (date 2-31)
        TenancyContract.Reset();
        TenancyContract.SetFilter("Contract Start Date", '%1..%2',
            DMY2Date(2, PreviousAllocationMonth, PreviousAllocationYear),
            PreviousAllocationEndDate);

        if TenancyContract.FindSet() then begin
            repeat
                // Additional check: Contract should be active during previous month
                if (TenancyContract."Contract Start Date" <= PreviousAllocationEndDate) and
                   (TenancyContract."Contract End Date" >= PreviousAllocationStartDate) then begin

                    // Check if this contract was missed in previous allocation
                    if IsMissedRevenueAllocationForContracts(
                        TenancyContract."Contract ID",
                        PreviousAllocationMonth,
                        PreviousAllocationYear,
                        pCurrentAllocation.Month,
                        pCurrentAllocation."Financial Year"
                    ) then begin

                        // Get revenue structure for this contract
                        RevenueStructure.Reset();
                        RevenueStructure.SetRange("Contract ID", TenancyContract."Contract ID");
                        RevenueStructure.SetFilter("Secondary Item Type", GetItemTypeFilter(SelectedItemTypes));

                        if RevenueStructure.FindSet() then begin
                            // Create temporary allocation record for missed month
                            TempRevenueAllocation := pCurrentAllocation;
                            TempRevenueAllocation.Month := PreviousAllocationMonth;
                            TempRevenueAllocation."Financial Year" := PreviousAllocationYear;

                            // Create missed revenue allocation for this contract
                            CreateMissedRevenueAllocationForContracts(
                                TenancyContract,
                                RevenueStructure,
                                TempRevenueAllocation
                            );

                            MissedContractCount += 1;
                        end;
                    end;
                end;
            until TenancyContract.Next() = 0;
        end;

        // Optional: Show message about missed contracts processed
        if MissedContractCount > 0 then
            Message('Processed %1 missed revenue allocations for previous month (%2/%3)',
                MissedContractCount, PreviousAllocationMonth, PreviousAllocationYear);
    end;

    // Enhanced check for missed revenue allocation - more dynamic
    local procedure IsMissedRevenueAllocationForContracts(
        ContractID: Integer;
        CheckMonth: Integer;
        CheckYear: Integer;
        currentMonth: Integer;
        currentYear: Integer
    ): Boolean
    var
        ExistingRevenue: Record "Revenue Recognition Details";
        RegularAllocationExists: Boolean;
        MissedAllocationExists: Boolean;
    begin
        // Check if regular revenue was already allocated for this contract in this month
        ExistingRevenue.Reset();
        ExistingRevenue.SetRange("Contract Id", ContractID);
        ExistingRevenue.SetRange("Posting Month", currentMonth);
        ExistingRevenue.SetRange("Posting Year", currentYear);
        ExistingRevenue.SetFilter("Posting Period", '<>%1', 'MISSED*'); // Exclude missed allocations

        RegularAllocationExists := not ExistingRevenue.IsEmpty;

        // Check if missed allocation already exists for this contract
        ExistingRevenue.Reset();
        ExistingRevenue.SetRange("Contract Id", ContractID);
        ExistingRevenue.SetRange("Posting Month", CheckMonth);
        ExistingRevenue.SetRange("Posting Year", CheckYear);
        ExistingRevenue.SetFilter("Posting Period", '%1', 'MISSED*'); // Only missed allocations

        MissedAllocationExists := not ExistingRevenue.IsEmpty;

        // Return true if no regular allocation exists AND no missed allocation exists
        exit(RegularAllocationExists and not MissedAllocationExists);
    end;

    // Create missed revenue allocation for a specific contract
    local procedure CreateMissedRevenueAllocationForContracts(
        pTenancyContract: Record "Tenancy Contract";
        pRevenueStructure: Record "Revenue Structure";
        pMissedAllocation: Record "Revenue Allocation Details"
    )
    var
        RevenueStructureSubpage: Record "Revenue Structure Subpage";
        SelectedItemTypes: List of [Text];
        ItemType: Text;
        ProcessedItemTypes: Integer;
    begin
        // Get selected item types
        GetSelectedItemTypess(SelectedItemTypes);

        ProcessedItemTypes := 0;

        // Process each selected item type for this contract
        foreach ItemType in SelectedItemTypes do begin
            // Get revenue structure subpage for this item type
            RevenueStructureSubpage.Reset();
            RevenueStructureSubpage.SetRange("Contract ID", pTenancyContract."Contract ID");
            RevenueStructureSubpage.SetRange("Secondary Item Type", ItemType);

            if RevenueStructureSubpage.FindFirst() then begin
                // Create missed revenue allocation record
                CreateSingleMissedRevenueAllocations(
                    pTenancyContract,
                    RevenueStructureSubpage,
                    pMissedAllocation,
                    ItemType
                );

                ProcessedItemTypes += 1;
            end;
        end;
    end;

    // Enhanced missed revenue allocation creation with better contract detection
    local procedure CreateSingleMissedRevenueAllocations(
        pTenancyContract: Record "Tenancy Contract";
        pRevenueStructureSubpage: Record "Revenue Structure Subpage";
        pMissedAllocation: Record "Revenue Allocation Details";
        pItemType: Text
    )
    var
        RevenueRecognitionDetails: Record "Revenue Recognition Details";
        PostingDate: Date;
        NextEntryNo: Integer;
        NoOfDays: Integer;
        MissedAllocationStartDate: Date;
        MissedAllocationEndDate: Date;
        FinalCalculation: Record "Final Calculation";
        TerminationDate: Date;
        SuspensionDate: Date;
        IsContractSuspended: Boolean;
        Yearlydays: Integer;
        ContractStartInMonth: Integer;
        ContractStartDay: Integer;
        permonthrent: Decimal;
    begin
        // Calculate missed month start and end dates
        MissedAllocationStartDate := DMY2Date(1, pMissedAllocation.Month, pMissedAllocation."Financial Year");
        MissedAllocationEndDate := CalcDate('CM', MissedAllocationStartDate);

        // Get contract start day to verify it's in range 2-31
        ContractStartDay := Date2DMY(pTenancyContract."Contract Start Date", 1);
        ContractStartInMonth := Date2DMY(pTenancyContract."Contract Start Date", 2);

        // Only process if contract started on day 2-31 of the previous month
        if (ContractStartInMonth = pMissedAllocation.Month) and (ContractStartDay >= 2) then begin

            // Convert Posting Month + Year to Date
            PostingDate := DMY2Date(1, pMissedAllocation.Month, pMissedAllocation."Financial Year");

            // Get termination date for this contract
            FinalCalculation.Reset();
            FinalCalculation.SetRange("Contract ID", pTenancyContract."Contract ID");
            if FinalCalculation.FindFirst() then
                TerminationDate := FinalCalculation."Termination Date"
            else
                TerminationDate := 0D;

            // Check if contract was suspended in the missed month
            IsContractSuspended := IsContractSuspendedInPeriods(
                pTenancyContract."Contract ID",
                pMissedAllocation.Month,
                pMissedAllocation."Financial Year",
                SuspensionDate
            );

            // Calculate number of days for missed allocation
            NoOfDays := CalculatePerfectNoOfDayss(
                pTenancyContract."Contract Start Date",
                pTenancyContract."Contract End Date",
                pMissedAllocation.Month,
                pMissedAllocation."Financial Year",
                TerminationDate,
                IsContractSuspended,
                SuspensionDate
            );

            // Create missed revenue record only if there are days to allocate
            if NoOfDays > 0 then begin
                // Get next entry number
                RevenueRecognitionDetails.Reset();
                if RevenueRecognitionDetails.FindLast() then
                    NextEntryNo := RevenueRecognitionDetails."Entry No." + 1
                else
                    NextEntryNo := 1;

                // Create new Revenue Recognition Detail record for missed allocation
                RevenueRecognitionDetails.Init();
                RevenueRecognitionDetails."Entry No." := NextEntryNo;
                RevenueRecognitionDetails."RR_No." := Rec."RR_No.";

                // Copy contract details
                RevenueRecognitionDetails."Contract Id" := pTenancyContract."Contract ID";
                RevenueRecognitionDetails."Property Name" := pTenancyContract."Property Name";
                RevenueRecognitionDetails."Customer Name" := pTenancyContract."Customer Name";
                RevenueRecognitionDetails."Contract Start Date" := pTenancyContract."Contract Start Date";
                RevenueRecognitionDetails."Contract End Date" := pTenancyContract."Contract End Date";
                RevenueRecognitionDetails."Owner Name" := pTenancyContract."Owner's Name";
                RevenueRecognitionDetails."Contract Tenure" := pTenancyContract."Contract Tenor";
                RevenueRecognitionDetails."Grace Days" := pTenancyContract."Grace Period";
                RevenueRecognitionDetails."Grace Start Date" := pTenancyContract."Grace Start Date";
                RevenueRecognitionDetails."Grace End Date" := pTenancyContract."Grace End Date";

                // Set unit names based on proposal type
                if pTenancyContract."Praposal Type Selected" = pTenancyContract."Praposal Type Selected"::"Single Unit" then
                    RevenueRecognitionDetails."Single Unit Names" := pTenancyContract."Unit Name"
                else if pTenancyContract."Praposal Type Selected" = pTenancyContract."Praposal Type Selected"::"Merge Unit" then
                    RevenueRecognitionDetails."Single Unit Names" := pTenancyContract."Single Unit Name"
                else
                    RevenueRecognitionDetails."Single Unit Names" := '';

                // Add missed allocation period details
                RevenueRecognitionDetails."Posting Month" := pMissedAllocation.Month;
                RevenueRecognitionDetails."Posting Year" := pMissedAllocation."Financial Year";

                // Mark as missed revenue allocation with contract start date info
                RevenueRecognitionDetails."Posting Period" :=
                    'MISSED: ' + FORMAT(pMissedAllocation.Month) + '/' + FORMAT(pMissedAllocation."Financial Year") +
                    ' (Started: ' + FORMAT(pTenancyContract."Contract Start Date") + ')';

                // Set termination date and number of days
                RevenueRecognitionDetails."Termination Date" := TerminationDate;
                RevenueRecognitionDetails."No Of Days" := NoOfDays;

                // Get suspension details
                GetSuspensionDetails(pTenancyContract."Contract ID", RevenueRecognitionDetails);

                // Set revenue structure details from subpage
                RevenueRecognitionDetails."Multi Year Start Date" := pRevenueStructureSubpage."Period Start Date";
                RevenueRecognitionDetails."Multi Year End Date" := pRevenueStructureSubpage."Period End Date";
                RevenueRecognitionDetails."Annual Amount" := pRevenueStructureSubpage."Final Annual Amount" + pRevenueStructureSubpage."Final Annual Amount" * 5 / 100;
                RevenueRecognitionDetails."Final Annual Amount" := RevenueRecognitionDetails."Annual Amount";
                RevenueRecognitionDetails."Item Type" := pItemType;
                RevenueRecognitionDetails."Contract Amount" := pRevenueStructureSubpage."Final Annual Amount";

                permonthrent := RevenueRecognitionDetails."Final Annual Amount" / 12;
                // Calculate amounts
                Yearlydays := RevenueRecognitionDetails."Multi Year End Date" - RevenueRecognitionDetails."Multi Year Start Date" + 1;
                RevenueRecognitionDetails."Per Month Rent" := Calculatepermonthrents(permonthrent, NoOfDays, pMissedAllocation.Month, pMissedAllocation."Financial Year"); // Use the per day rent passed from the grid

                RevenueRecognitionDetails."Total Value" := RevenueRecognitionDetails."No Of Days" * RevenueRecognitionDetails."Per Day Rent";
                RevenueRecognitionDetails."Owner Share" := RevenueRecognitionDetails."Total Value";

                // Insert the missed revenue record
                RevenueRecognitionDetails.Insert(true);
            end;
        end;
    end;

    // Perfect calculation of number of days - enhanced for missed allocations
    local procedure CalculatePerfectNoOfDayss(
        ContractStartDate: Date;
        ContractEndDate: Date;
        ProcessMonth: Integer;
        ProcessYear: Integer;
        TerminationDate: Date;
        IsContractSuspended: Boolean;
        SuspensionDate: Date
    ): Integer
    var
        MonthStartDate: Date;
        MonthEndDate: Date;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        NoOfDays: Integer;
    begin
        // Calculate month boundaries
        MonthStartDate := DMY2Date(1, ProcessMonth, ProcessYear);
        MonthEndDate := CalcDate('CM', MonthStartDate);

        // For missed allocations, use the actual contract start date if it's within the month
        if (ContractStartDate >= MonthStartDate) and (ContractStartDate <= MonthEndDate) then
            EffectiveStartDate := ContractStartDate
        else
            EffectiveStartDate := MonthStartDate;

        // Determine effective end date (earlier of contract end, month end, or termination date)
        EffectiveEndDate := MonthEndDate;

        if ContractEndDate < EffectiveEndDate then
            EffectiveEndDate := ContractEndDate;

        if (TerminationDate <> 0D) and (TerminationDate < EffectiveEndDate) then
            EffectiveEndDate := TerminationDate;

        // Handle suspension
        if IsContractSuspended and (SuspensionDate <> 0D) and (SuspensionDate < EffectiveEndDate) then
            EffectiveEndDate := SuspensionDate;

        // Calculate number of days
        if EffectiveEndDate >= EffectiveStartDate then
            NoOfDays := EffectiveEndDate - EffectiveStartDate + 1
        else
            NoOfDays := 0;

        exit(NoOfDays);
    end;



    // UPDATED: Function to check if contract should be processed
    local procedure ShouldProcessContracts(pTenancyContract: Record "Tenancy Contract"; pAllocationMonth: Integer; pAllocationYear: Integer): Boolean
    begin
        // 1. If Active - Always process
        if pTenancyContract."Tenant Contract Status" = pTenancyContract."Tenant Contract Status"::Active then
            exit(true);

        // 2. If Suspended - Check if suspension date falls in selected month/year
        if pTenancyContract."Tenant Contract Status" = pTenancyContract."Tenant Contract Status"::Suspended then begin
            if HasSuspensionInSelectedPeriods(pTenancyContract."Contract ID", pAllocationMonth, pAllocationYear) then
                exit(true);
        end;

        // 3. If Terminated - Check if termination date falls in selected month/year
        if pTenancyContract."Tenant Contract Status" = pTenancyContract."Tenant Contract Status"::Terminated then begin
            if HasTerminationInSelectedPeriods(pTenancyContract."Contract ID", pAllocationMonth, pAllocationYear) then
                exit(true);
        end;

        // Default: Don't process
        exit(false);
    end;

    // NEW: Check if suspension date falls in selected month/year
    local procedure HasSuspensionInSelectedPeriods(pContractID: Integer; pAllocationMonth: Integer; pAllocationYear: Integer): Boolean
    var
        SuspendedReasonList: Record SuspendReasonTable;
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
    begin
        // Calculate selected month start and end dates
        SelectedMonthStart := DMY2Date(1, pAllocationMonth, pAllocationYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Check if suspension date falls within selected period
        SuspendedReasonList.Reset();
        SuspendedReasonList.SetRange("Contract ID", pContractID);
        if SuspendedReasonList.FindFirst() then begin
            if (SuspendedReasonList.DateEffective >= SelectedMonthStart) and
               (SuspendedReasonList.DateEffective <= SelectedMonthEnd) then
                exit(true);
        end;

        exit(false);
    end;

    // NEW: Check if termination date falls in selected month/year
    local procedure HasTerminationInSelectedPeriods(pContractID: Integer; pAllocationMonth: Integer; pAllocationYear: Integer): Boolean
    var
        FinalCalculation: Record "Final Calculation";
        SelectedMonthStart: Date;
        SelectedMonthEnd: Date;
    begin
        // Calculate selected month start and end dates
        SelectedMonthStart := DMY2Date(1, pAllocationMonth, pAllocationYear);
        SelectedMonthEnd := CALCDATE('<+1M-1D>', SelectedMonthStart);

        // Check if termination date falls within selected period
        FinalCalculation.Reset();
        FinalCalculation.SetRange("Contract ID", pContractID);
        if FinalCalculation.FindFirst() then begin
            if (FinalCalculation."Termination Date" <> 0D) and
               (FinalCalculation."Termination Date" >= SelectedMonthStart) and
               (FinalCalculation."Termination Date" <= SelectedMonthEnd) then
                exit(true);
        end;

        exit(false);
    end;

    local procedure GetSelectedItemTypess(var pItemTypes: List of [Text])
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

    local procedure GetItemTypeFilters(pItemTypes: List of [Text]): Text
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

    procedure CalculateNoOfDayss(
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
    local procedure CalculateSuspendedPeriodDayss(
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
    local procedure HasSuspensionToActiveScenarios(
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

    // Alternative approach: If you want to check active status at field level
    local procedure IsContractActiveByStatuss(ContractID: Integer): Boolean
    var
        TenancyContract: Record "Tenancy Contract";
    begin
        TenancyContract.Reset();
        TenancyContract.SetRange("Contract ID", ContractID);
        if TenancyContract.FindFirst() then begin
            // Adjust field name based on your table structure
            if TenancyContract."Tenant Contract Status" = TenancyContract."Tenant Contract Status"::Active then
                exit(true);
            // OR
            // if TenancyContract."Contract Status" = 'Active' then
            //     exit(true);
        end;
        exit(false);
    end;

    // NEW: Function to check if contract is suspended in selected month/year
    local procedure IsContractSuspendedInPeriods(
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
    local procedure CalculateSuspendedContractDayss(
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
    local procedure CreateRevenueRecognitionDetailDirects(
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
        IsContractSuspended := IsContractSuspendedInPeriods(
            pTenancyContract."Contract ID",
            pRevenueAllocation.Month,
            pRevenueAllocation."Financial Year",
            SuspensionDate
        );

        // Calculate number of days based on suspension status
        if IsContractSuspended then begin
            // For suspended contracts, calculate days only till suspension date
            NoOfDays := CalculateSuspendedContractDayss(
                pTenancyContract."Contract Start Date",
                pTenancyContract."Contract End Date",
                pRevenueAllocation.Month,
                pRevenueAllocation."Financial Year",
                SuspensionDate
            );
        end else begin
            // For normal contracts, use existing logic
            NoOfDays := CalculateNoOfDayss(
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
            CreateRevenueRecords(
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
        if HasSuspensionToActiveScenarios(
            pTenancyContract."Contract ID",
            RevenueAllocationStartDate,
            RevenueAllocationEndDate,
            SuspensionStartDate,
            SuspensionEndDate
        ) then begin
            SuspendedPeriodDays := CalculateSuspendedPeriodDayss(
                SuspensionStartDate,
                SuspensionEndDate,
                RevenueAllocationEndDate
            );

            if SuspendedPeriodDays > 0 then begin
                CreateRevenueRecords(
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
    local procedure CreateRevenueRecords(
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
        permonthrent: Decimal;
    begin
        // Get next entry number
        RevenueRecognitionDetails.Reset();
        if RevenueRecognitionDetails.FindLast() then
            NextEntryNo := RevenueRecognitionDetails."Entry No." + 1
        else
            NextEntryNo := 1;

        PostingDate := DMY2Date(1, pRevenueAllocation.Month, pRevenueAllocation."Financial Year");




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
        GetTerminationDates(pTenancyContract."Contract ID", RevenueRecognitionDetails);

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
        GetSuspensionDetailss(pTenancyContract."Contract ID", RevenueRecognitionDetails);

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

        permonthrent := RevenueRecognitionDetails."Final Annual Amount" / 12;
        Yearlydays := RevenueRecognitionDetails."Multi Year End Date" - RevenueRecognitionDetails."Multi Year Start Date" + 1;
        RevenueRecognitionDetails."Per Month Rent" := calculatepermonthrent(permonthrent, ActualNoOfDays, pRevenueAllocation.Month, pRevenueAllocation."Financial Year"); // Use the per day rent passed from the grid
        RevenueRecognitionDetails."Total Value" := RevenueRecognitionDetails."No Of Days" * RevenueRecognitionDetails."Per Month Rent";
        RevenueRecognitionDetails."Owner Share" := RevenueRecognitionDetails."Total Value";

        // Insert the record
        RevenueRecognitionDetails.Insert(true);
    end;

    // Get termination date from Final Calculation table
    local procedure GetTerminationDates(ContractID: Integer; var RevenueRecognitionDetails: Record "Revenue Recognition Details")
    var
        FinalCalculation: Record "Final Calculation";
    begin
        FinalCalculation.Reset();
        FinalCalculation.SetRange("Contract ID", ContractID);
        if FinalCalculation.FindFirst() then
            RevenueRecognitionDetails."Termination Date" := FinalCalculation."Termination Date";
    end;

    // Get suspension details from Suspended Reason table
    local procedure GetSuspensionDetailss(ContractID: Integer; var RevenueRecognitionDetails: Record "Revenue Recognition Details")
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


    procedure Calculatepermonthrent(permonthrent: Decimal; ActualNoOfDays: Integer; MonthNo: Integer; FinancialYear: Integer): Decimal
    var
        revenuerecognition: Record "Revenue Recognition";
        MonthlyRate: Decimal;
    begin

        if ActualNoOfDays < revenuerecognition.GetDaysInMonthss(DMY2Date(1, MonthNo, FinancialYear)) then begin
            MonthlyRate := Round(permonthrent / revenuerecognition.GetDaysInMonthss(DMY2Date(1, MonthNo, FinancialYear)) * ActualNoOfDays);
        end else begin
            MonthlyRate := permonthrent;
        end;
        exit(MonthlyRate);
    end;

    procedure Calculatepermonthrents(permonthrent: Decimal; NoOfDays: Integer; MonthNo: Integer; FinancialYear: Integer): Decimal
    var
        revenuerecognition: Record "Revenue Recognition";
        MonthlyRate: Decimal;
    begin

        if NoOfDays < revenuerecognition.GetDaysInMonthss(DMY2Date(1, MonthNo, FinancialYear)) then begin
            MonthlyRate := Round(permonthrent / revenuerecognition.GetDaysInMonthss(DMY2Date(1, MonthNo, FinancialYear)) * NoOfDays);
        end else begin
            MonthlyRate := permonthrent;
        end;
        exit(MonthlyRate);
    end;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
