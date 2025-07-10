table 50318 "Contract Renewal"
{
    DataClassification = ToBeClassified;
    DataCaptionFields = "ID";

    fields
    {
        field(50101; "Id"; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }


        field(50100; "Owner's Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Owner Name';
            TableRelation = "Owner Profile"."Full Name";
        }

        field(50114; "Lessor's Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Lessor Name';
        }

        field(50115; "Lessor's Emirates ID"; Code[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'Lessor Emirates ID';
        }

        field(50116; "License No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'License No.';
            // Note: You can add additional logic or relations if needed
        }

        field(50117; "Licensing Authority"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Licensing Authority';
        }

        field(50118; "Lessor's Email"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Lessor Email';
        }

        field(50119; "Lessor's Phone"; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Lessor Phone';
        }

        field(50102; "Contract ID"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract ID';
            TableRelation = "Tenancy Contract"."Contract ID";


            trigger OnValidate()
            var
                TenancyContractRec: Record "Tenancy Contract";
                EndDate: Date;



            begin
                // Fetch details if Contract ID is valid
                TenancyContractRec.SetRange("Contract ID", "Contract ID");
                if TenancyContractRec.FindFirst() then begin

                    EndDate := TenancyContractRec."Contract End Date" + 1;

                    // Set the new start date (contract start date + 1 day)
                    "Contract Start Date" := EndDate;


                    // "Contract Start Date" := TenancyContractRec."Contract End Date";
                    // "Contract End Date" := TenancyContractRec."Contract End Date";
                    "Contract Amount" := TenancyContractRec."Annual Rent Amount";
                    "Unit ID" := TenancyContractRec."Unit ID";
                    "Unit Name" := TenancyContractRec."Unit Name";
                    "Property ID" := TenancyContractRec."Property ID";
                    "Property Name" := TenancyContractRec."Property Name";
                    "Tenant Full Name" := TenancyContractRec."Customer Name";
                    // "Contract Tenor" := TenancyContractRec."Contract Tenor";
                    "Owner's Name" := TenancyContractRec."Owner's Name";
                    "Lessor's Name" := TenancyContractRec."Lessor's Name";
                    "Lessor's Emirates ID" := TenancyContractRec."Lessor's Emirates ID";
                    "License No." := TenancyContractRec."License No.";
                    "Licensing Authority" := TenancyContractRec."Licensing Authority";
                    "Lessor's Email" := TenancyContractRec."Lessor's Email";
                    "Proposal ID" := TenancyContractRec."Proposal ID";
                    "Ejari Name" := TenancyContractRec."Ejari Name";
                    "Property Classification" := TenancyContractRec."Property Classification";
                    "Property Type" := TenancyContractRec."Property Type";
                    "Annual Rent Amount" := TenancyContractRec."Annual Rent Amount";
                    // "Contract Date" := TenancyContractRec."Contract Date";
                    "Base Unit of Measure" := TenancyContractRec."Base Unit of Measure";
                    "Unit Sq. Feet" := TenancyContractRec."Unit Sq. Feet";
                    "Grace Period" := TenancyContractRec."Grace Period";
                    "Grace Start Date" := TenancyContractRec."Grace Start Date";
                    "Grace End Date" := TenancyContractRec."Grace End Date";
                    "Tenant ID" := TenancyContractRec."Tenant ID";
                    "Emirates ID" := TenancyContractRec."Emirates ID";
                    "Contact Number" := TenancyContractRec."Contact Number";
                    "Email Address" := TenancyContractRec."Email Address";
                    "Payment Frequency" := TenancyContractRec."Payment Frequency";
                    "Payment Method" := TenancyContractRec."Payment Method";
                    "Created By" := TenancyContractRec."Created By";
                    "Merge Unit ID" := TenancyContractRec."Merge Unit ID";
                    "Rent Amount" := TenancyContractRec."Rent Amount";
                    "Tenant_License No." := TenancyContractRec."Tenant_License No.";
                    "Tenant_Licensing Authority" := TenancyContractRec."Tenant_Licensing Authority";
                    "Security Deposit Amount" := TenancyContractRec."Security Deposit Amount";
                    "Unit Number" := TenancyContractRec."Unit Number";
                    "Makani Number" := TenancyContractRec."Makani Number";
                    Emirate := TenancyContractRec.Emirate;
                    Community := TenancyContractRec.Community;
                    "Property Size" := TenancyContractRec."Property Size";
                    "No of Installments" := TenancyContractRec."No of Installments";
                    "DEWA Number" := TenancyContractRec."DEWA Number";
                    UnitID := TenancyContractRec.UnitID;
                    "Lessor's Phone" := TenancyContractRec."Lessor's Phone";
                    "Praposal Type Selected" := TenancyContractRec."Praposal Type Selected";
                    "Rent Amount VAT %" := TenancyContractRec."Contract VAT %";
                    "Rent VAT Amount" := TenancyContractRec."Contract VAT Amount";
                    "Rent Amount Including VAT" := TenancyContractRec."Contract Amount Including VAT";

                end else begin
                    // Clear fields if no record is found
                    Clear("Contract Start Date");
                    Clear("Contract End Date");
                    Clear("Contract Amount");
                    Clear("Unit ID");
                    Clear("Unit Name");
                    Clear("Property ID");
                    Clear("Property Name");
                end;



            end;
        }

        field(50103; "Contract Start Date"; Date)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()

            begin
                ;

                CalculateLeaseDuration();

            end;

        }

        field(50104; "Contract End Date"; Date)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()

            // var
            //     MergedUnitRec: Record "Merged Units";
            //     MergeUnitGrid: Record "Sub Merged Units";
            //     MergeUnitLeaseGrid: Record "CR Sub Lease Merged Units";
            //     ItemRec: Record Item;

            //     SelectedUnits: Text[1024];
            //     mergeUnitId: Integer;
            begin


                // Evaluate(mergeUnitId, Rec."Merge Unit ID");

                // // Delete old records for the selected Merge Unit ID
                // MergeUnitLeaseGrid.SetRange("Merge Unit ID", FORMAT(mergeUnitId));
                // if MergeUnitLeaseGrid.FindSet() then
                //     repeat
                //         MergeUnitLeaseGrid.Delete();
                //     until MergeUnitLeaseGrid.Next() = 0;

                // // Insert new records for the selected Merge Unit ID
                // MergeUnitGrid.SetRange("Merged Unit ID", mergeUnitId);
                // if MergeUnitGrid.FindSet() then
                //     repeat
                //         MergeUnitLeaseGrid.Init();
                //         MergeUnitLeaseGrid."Merge Unit ID" := FORMAT(MergeUnitGrid."Merged Unit ID");
                //         MergeUnitLeaseGrid."ID" := Rec."ID";
                //         MergeUnitLeaseGrid."Single Unit Name" := MergeUnitGrid."Single Unit Name";
                //         MergeUnitLeaseGrid."Unit ID" := MergeUnitGrid."Unit ID";
                //         MergeUnitLeaseGrid."Base Unit of Measure" := MergeUnitGrid."Base Unit of Measure";
                //         MergeUnitLeaseGrid."Unit Size" := MergeUnitGrid."Unit Size";
                //         MergeUnitLeaseGrid."Unit Name" := MergeUnitGrid."Unit Name";
                //         MergeUnitLeaseGrid."Market Rate per Square" := MergeUnitGrid."Market Rate per Square";
                //         MergeUnitLeaseGrid.Amount := MergeUnitGrid.Amount;
                //         MergeUnitLeaseGrid.Insert();
                //     until MergeUnitGrid.Next() = 0;



                CalculateLeaseDuration();

            end;
        }

        field(50105; "Contract Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(50106; "Unit ID"; Code[20])
        {
            DataClassification = ToBeClassified;
        }

        field(50107; "Unit Name"; Text[100])
        {
            DataClassification = ToBeClassified;
        }

        field(50108; "Property ID"; Code[20])
        {
            DataClassification = ToBeClassified;
        }

        field(50109; "Property Name"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(50110; "Renewal Contract Status"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",Active,"Renewal of Original Contract ID";
            Editable = false;



            trigger OnValidate()
            var
                TenancyContractRec: Record "Tenancy Contract";
                emailrec: Codeunit "Send Contract Renewal Email";
            begin
                if "Renewal Contract Status" = "Renewal Contract Status"::"Renewal of Original Contract ID" then begin
                    // Filter and find the corresponding Tenancy Contract record
                    TenancyContractRec.SetRange("Contract ID", "Contract ID");
                    if TenancyContractRec.FindFirst() then begin
                        // Update the Tenancy Contract Status
                        TenancyContractRec."Tenant Contract Status" :=
                            TenancyContractRec."Tenant Contract Status"::"Active-Contract Renewed";
                        TenancyContractRec.Modify(); // Save the changes

                        // Confirm the update
                        Message('Tenancy Contract ID %1 updated to "Active-Contract Renewed".', "Contract ID");
                    end else
                        Error('No Tenancy Contract found with Contract ID %1.', "Contract ID");
                end;
                if Rec."Renewal Contract Status" = Rec."Renewal Contract Status"::"Renewal of Original Contract ID" then begin
                    emailrec.SendEmail(Rec);
                end;
            end;

        }

        field(50111; "Tenant Full Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            // TableRelation = Customer.Name;
        }

        field(50112; "Contract Tenor"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract Period (Months)';
        }

        field(50113; "Approval For Renewal"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Approval For Renewal';
            OptionMembers = " ","Request For Renewal";
        }

        field(50120; "Proposal ID"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Proposal ID';
        }

        field(50125; "Ejari Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Ejari Name';
        }

        field(50124; "Property Classification"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Property Classification';
            TableRelation = "Primary Classification"."Classification Name";
            NotBlank = true;
        }

        field(50122; "Property Type"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Property Type';
            TableRelation = "Secondary Classification"."Property Type"
                where("Classification Name" = field("Property Classification"));
        }

        field(50121; "Annual Rent Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Rent Amount ';
        }

        field(50127; "Contract Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract Date';

            trigger OnValidate()

            var
                MergedUnitRec: Record "Merged Units";
                MergeUnitGrid: Record "Sub Merged Units";
                MergeUnitLeaseGrid: Record "CR Sub Lease Merged Units";
                ItemRec: Record Item;

                SelectedUnits: Text[1024];
                mergeUnitId: Integer;
            begin


                Evaluate(mergeUnitId, Rec."Merge Unit ID");

                // Delete old records for the selected Merge Unit ID
                MergeUnitLeaseGrid.SetRange("Merge Unit ID", FORMAT(mergeUnitId));
                if MergeUnitLeaseGrid.FindSet() then
                    repeat
                        MergeUnitLeaseGrid.Delete();
                    until MergeUnitLeaseGrid.Next() = 0;

                // Insert new records for the selected Merge Unit ID
                MergeUnitGrid.SetRange("Merged Unit ID", mergeUnitId);
                if MergeUnitGrid.FindSet() then
                    repeat
                        MergeUnitLeaseGrid.Init();
                        MergeUnitLeaseGrid."Merge Unit ID" := FORMAT(MergeUnitGrid."Merged Unit ID");
                        MergeUnitLeaseGrid."ID" := Rec."ID";
                        MergeUnitLeaseGrid."Single Unit Name" := MergeUnitGrid."Single Unit Name";
                        MergeUnitLeaseGrid."Unit ID" := MergeUnitGrid."Unit ID";
                        MergeUnitLeaseGrid."Base Unit of Measure" := MergeUnitGrid."Base Unit of Measure";
                        MergeUnitLeaseGrid."Unit Size" := MergeUnitGrid."Unit Size";
                        MergeUnitLeaseGrid."Unit Name" := MergeUnitGrid."Unit Name";
                        MergeUnitLeaseGrid."Market Rate per Square" := MergeUnitGrid."Market Rate per Square";
                        MergeUnitLeaseGrid.Amount := MergeUnitGrid.Amount;
                        MergeUnitLeaseGrid.Insert();
                    until MergeUnitGrid.Next() = 0;





            end;

        }

        field(50128; "Base Unit of Measure"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Base Unit of Measure';

        }

        field(50129; "Unit Sq. Feet"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Unit Size';
        }

        field(50130; "Grace Period"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Grace Period (Days)';
        }

        field(50131; "Grace Start Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Grace Start Date';

        }

        field(50132; "Grace End Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Grace End Date';


        }

        field(50133; "Tenant ID"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Tenant ID';
            TableRelation = Customer."No.";
        }

        field(50134; "Emirates ID"; Code[15])
        {
            DataClassification = ToBeClassified;
            Caption = 'Emirates ID';
        }

        field(50135; "Contact Number"; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Contact Number';
        }
        field(50136; "Email Address"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Email Address';
        }

        field(50137; "Payment Frequency"; Option)
        {
            OptionMembers = Monthly,Quarterly,Yearly;
            DataClassification = ToBeClassified;
        }
        field(50138; "Payment Method"; Text[100])
        {
            DataClassification = ToBeClassified;
        }

        field(50139; "Created By"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Created By';
        }

        field(50149; "Merge Unit ID"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Merge Unit ID';
            // TableRelation = "Merged Units"."Merged Unit ID"
            //      where("Property ID" = field("Property ID"));


        }

        field(50150; "Rent Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Annual Rent Amount ';
        }


        field(50140; "Tenant_License No."; Code[20])
        {
            Caption = 'Tenant Trade License No.';
            DataClassification = ToBeClassified;
        }

        field(50141; "Tenant_Licensing Authority"; Text[100])
        {
            Caption = 'Tenant_Licensing Authority';
            DataClassification = ToBeClassified;
        }


        field(50143; "Unit Number"; Code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(50144; "Makani Number"; Text[50])
        {
            DataClassification = ToBeClassified;

        }
        field(50145; "Emirate"; Text[100])
        {
            DataClassification = ToBeClassified;

        }
        field(50146; "Community"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(50147; "DEWA Number"; Text[50])
        {
            Caption = 'DEWA Number';
            DataClassification = ToBeClassified;
        }
        field(50148; "Property Size"; Code[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Property Size';
        }
        field(50151; "No of Installments"; Integer)
        {
            Caption = 'No of Installments';
            Editable = false;
        }

        field(50152; "UnitID"; code[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Uniq Unit ID';

        }

        field(50153; "Original Contract ID"; code[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Original Contract ID';

        }

        field(50154; "Final Status"; Option)
        {
            OptionMembers = " ",Approved,Reject;
            DataClassification = ToBeClassified;
        }

        field(50155; "Contract Status"; Option)
        {
            OptionMembers = " ",Active;
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                TenancyContractRec: Record "Tenancy Contract";
            begin
                if "Contract Status" = "Contract Status"::Active then begin
                    // Set a filter to find the Tenancy Contract record associated with this Contract Renewal ID
                    TenancyContractRec.SetRange("Renewal Proposal ID", "Id");
                    if TenancyContractRec.FindSet() then begin
                        repeat
                            // Update the Tenant Contract Status to Active
                            TenancyContractRec."Tenant Contract Status" :=
                                TenancyContractRec."Tenant Contract Status"::Active;
                            TenancyContractRec.Modify(); // Save changes
                        until TenancyContractRec.Next() = 0;
                    end;
                end;
            end;

        }
        field(50156; "Rera"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Rera';

        }
        field(50157; "Ejari Processing Charges"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Ejari Processing Charges';

        }
        field(50158; "Renewal Charges"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Renewal Charges';

        }

        field(50159; "Praposal Type Selected"; Option)
        {
            OptionMembers = " ","Single Unit","Merge Unit";
            DataClassification = ToBeClassified;

        }

        field(50160; "Single Rent Calculation"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Single Unit Rent Calculation Type';
            OptionMembers = " ","Single Unit with square feet rate","Single Unit with lumpsum square feet rate";

            trigger OnValidate()

            var
                LeaseProposal: Record "Contract Renewal"; // Replace with actual table name
                SingleSameSquare: Record "CR Single Unit Rent SubPage"; // Target table
                SingleLumSquare: Record "CR Single LumAnnualAmnt SP"; // Target table
                PeriodStartDate: Date;
                PeriodEndDate: Date;
                LeaseEndDate: Date;
                TotalDays: Integer;
                DaysToAdd: Integer;
                LeapDays: Integer;
                CurrentYear: Integer;
                YearCounter: Integer;
                LineNoCounter: Integer;


            begin

                if "Single Rent Calculation" = "Single Rent Calculation"::"Single Unit with square feet rate" then begin
                    SingleSameSquare.SetRange("ID", Rec."ID");
                    if SingleSameSquare.FindSet() then
                        repeat
                            SingleSameSquare.Delete();
                        until SingleSameSquare.Next() = 0;

                    // Initialize variables
                    PeriodStartDate := Rec."Contract Start Date";
                    LeaseEndDate := Rec."Contract End Date";
                    YearCounter := 1;
                    LineNoCounter := 1;

                    // Loop to divide the period into yearly chunks and create records
                    while PeriodStartDate <= LeaseEndDate do begin
                        SingleSameSquare.Init();
                        SingleSameSquare."ID" := Rec."ID";
                        SingleSameSquare."Line No." := LineNoCounter;
                        SingleSameSquare.Year := YearCounter;
                        SingleSameSquare."Start Date" := PeriodStartDate;

                        // Calculate the End Date (365 days after Start Date, adjusted for leap years)
                        DaysToAdd := 365; // Default to 365 days
                        LeapDays := 0;

                        // Check for leap years in the range from Start Date to Start Date + 364 days
                        for CurrentYear := Date2DMY(PeriodStartDate, 3) to Date2DMY(PeriodStartDate + 364, 3) do begin
                            if IsLeapYear(CurrentYear) then begin
                                // Ensure the leap day (Feb 29) falls within the range
                                if (DMY2Date(29, 2, CurrentYear) >= PeriodStartDate) and
                                   (DMY2Date(29, 2, CurrentYear) <= PeriodStartDate + DaysToAdd - 1) then
                                    LeapDays += 1;
                            end;
                        end;

                        // Adjust DaysToAdd to account for any leap days
                        DaysToAdd := DaysToAdd + LeapDays;

                        // Calculate the PeriodEndDate
                        PeriodEndDate := PeriodStartDate + DaysToAdd - 1;

                        // Ensure the End Date does not exceed the Lease End Date
                        if PeriodEndDate > LeaseEndDate then
                            PeriodEndDate := LeaseEndDate;

                        SingleSameSquare."End Date" := PeriodEndDate;

                        // Calculate the number of days for this chunk
                        TotalDays := PeriodEndDate - PeriodStartDate + 1;
                        SingleSameSquare."Number of Days" := TotalDays;

                        // Populate other fields
                        SingleSameSquare."Unit ID" := Rec."Unit Name";
                        SingleSameSquare."Unit Sq Ft" := Rec."Unit Sq. Feet";

                        // Set default values for Rate per Sq.Ft and Annual Amount (to be manually entered)
                        SingleSameSquare."Rate per Sq.Ft" := 0; // Initialize as 0; users will manually enter this
                        SingleSameSquare."Annual Amount" := 0; // Calculated after manual input

                        // Set Final Annual Amount to match Annual Amount
                        SingleSameSquare."Final Annual Amount" := SingleSameSquare."Annual Amount";

                        // Calculate Per Day Rent
                        SingleSameSquare."Per Day Rent" := 0; // Will be calculated after manual input

                        SingleSameSquare.Insert();

                        // Move to the next period
                        PeriodStartDate := PeriodEndDate + 1;
                        YearCounter += 1;
                        LineNoCounter += 1;
                    end;
                end
                else if "Single Rent Calculation" = "Single Rent Calculation"::"Single Unit with lumpsum square feet rate" then begin

                    if Rec."ID" = 0 then
                        Error('Contract Renewal ID is missing or not assigned.');

                    LeaseProposal.Reset();
                    LeaseProposal.SetRange("ID", Rec."ID");

                    if not LeaseProposal.FindFirst() then
                        Error('No record found for Contract Renewal ID %1.', Rec."ID");

                    // Delete existing records to avoid duplication
                    SingleLumSquare.SetRange("ID", LeaseProposal."ID");
                    if SingleLumSquare.FindSet() then
                        repeat
                            SingleLumSquare.Delete();
                        until SingleLumSquare.Next() = 0;

                    PeriodStartDate := LeaseProposal."Contract Start Date";
                    YearCounter := 1;
                    LineNoCounter := 1;

                    // Loop to divide the period into yearly chunks and create records
                    while PeriodStartDate <= LeaseProposal."Contract End Date" do begin
                        SingleLumSquare.Init();
                        SingleLumSquare."ID" := LeaseProposal."ID";
                        SingleLumSquare."SL_Line No." := LineNoCounter;
                        SingleLumSquare.SL_Year := YearCounter;
                        SingleLumSquare."SL_Start Date" := PeriodStartDate;

                        // Calculate the End Date (365 days after Start Date, adjusted for leap years)
                        DaysToAdd := 365; // Default to 365 days
                        LeapDays := 0;

                        // Check for leap years in the range from Start Date to Start Date + 364 days
                        for CurrentYear := Date2DMY(PeriodStartDate, 3) to Date2DMY(PeriodStartDate + 364, 3) do begin
                            if IsLeapYear(CurrentYear) then begin
                                // Ensure the leap day (Feb 29) falls within the range
                                if (DMY2Date(29, 2, CurrentYear) >= PeriodStartDate) and
                                   (DMY2Date(29, 2, CurrentYear) <= PeriodStartDate + DaysToAdd - 1) then
                                    LeapDays += 1;
                            end;
                        end;

                        // Adjust DaysToAdd to account for any leap days
                        DaysToAdd := DaysToAdd + LeapDays;

                        // Calculate the PeriodEndDate
                        PeriodEndDate := PeriodStartDate + DaysToAdd - 1;

                        // Ensure the end date does not exceed the Lease End Date
                        if PeriodEndDate > LeaseProposal."Contract End Date" then
                            PeriodEndDate := LeaseProposal."Contract End Date";

                        SingleLumSquare."SL_End Date" := PeriodEndDate;

                        // Calculate the number of days
                        TotalDays := PeriodEndDate - PeriodStartDate + 1;
                        SingleLumSquare."SL_Number of Days" := TotalDays;

                        // Populate other fields
                        SingleLumSquare."SL_Unit ID" := LeaseProposal."Unit Name";
                        SingleLumSquare."SL_Unit Sq Ft" := LeaseProposal."Unit Sq. Feet";

                        // For the first year, initialize the Annual Amount and Final Annual Amount
                        if YearCounter = 1 then begin
                            SingleLumSquare."SL_Annual Amount" := 0; // User will enter manually
                            SingleLumSquare."SL_Final Annual Amount" := 0;
                        end;

                        // Calculate Per Day Rent
                        if TotalDays > 0 then
                            SingleLumSquare."SL_Per Day Rent" := SingleLumSquare."SL_Final Annual Amount" / TotalDays
                        else
                            SingleLumSquare."SL_Per Day Rent" := 0;

                        SingleLumSquare.Insert();

                        // Update for the next year
                        PeriodStartDate := PeriodEndDate + 1;
                        YearCounter += 1;
                        LineNoCounter += 1;
                    end;
                end;
            end;

        }
        field(50161; "Merge Rent Calculation"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Merge Unit Rent Calculation Type';
            OptionMembers = " ","Merged Unit with same square feet","Merged Unit with differential square feet rate","Merged Unit with lumpsum annual amount";
            //    OptionCaption = ' ', 'Single Unit with square feet rate', 'Merged Unit with same square feet',
            //              'Merged Unit with differential square feet rate', 'Merged Unit with lumpsum annual amount';

            trigger OnValidate()

            var


                LeaseProposal: Record "Contract Renewal"; // Replace with actual table name
                MergeSameSquare: Record "CR Merge SameSqure SubPage"; // Target table
                MergeDiffSquare: Record "CR Merge DifferentSq SubPage"; // Target table
                MergeLumSquare: Record "CR Merge LumAnnualAmount SP";
                SubLeaseMergeRec: Record "CR Sub Lease Merged Units";
                // Target table
                PeriodStartDate: Date;
                PeriodEndDate: Date;
                LeaseEndDate: Date;
                TotalDays: Integer;
                DaysToAdd: Integer;
                LeapDays: Integer;
                CurrentYear: Integer;
                YearCounter: Integer;
                LineNoCounter: Integer;


            begin

                if "Merge Rent Calculation" = "Merge Rent Calculation"::"Merged Unit with same square feet" then begin
                    MergeSameSquare.SetRange("ID", Rec."ID");
                    if MergeSameSquare.FindSet() then
                        repeat
                            MergeSameSquare.Delete();
                        until MergeSameSquare.Next() = 0;

                    // Initialize variables
                    PeriodStartDate := Rec."Contract Start Date";
                    LeaseEndDate := Rec."Contract End Date";
                    YearCounter := 1;
                    LineNoCounter := 1;

                    // Loop to divide the period into yearly chunks and create records
                    while PeriodStartDate <= LeaseEndDate do begin
                        MergeSameSquare.Init();
                        MergeSameSquare."ID" := Rec."ID";
                        MergeSameSquare."MS_Line No." := LineNoCounter;
                        MergeSameSquare.MS_Year := YearCounter;
                        MergeSameSquare."MS_Start Date" := PeriodStartDate;

                        // Calculate the End Date (365 days after Start Date, adjusted for leap years)
                        DaysToAdd := 365; // Default to 365 days
                        LeapDays := 0;

                        // Check for leap years in the range from Start Date to Start Date + 364 days
                        for CurrentYear := Date2DMY(PeriodStartDate, 3) to Date2DMY(PeriodStartDate + 364, 3) do begin
                            if IsLeapYear(CurrentYear) then begin
                                // Ensure the leap day (Feb 29) falls within the range
                                if (DMY2Date(29, 2, CurrentYear) >= PeriodStartDate) and
                                   (DMY2Date(29, 2, CurrentYear) <= PeriodStartDate + DaysToAdd - 1) then
                                    LeapDays += 1;
                            end;
                        end;

                        // Adjust DaysToAdd to account for any leap days
                        DaysToAdd := DaysToAdd + LeapDays;

                        // Calculate the PeriodEndDate
                        PeriodEndDate := PeriodStartDate + DaysToAdd - 1;

                        // Ensure the End Date does not exceed the Lease End Date
                        if PeriodEndDate > LeaseEndDate then
                            PeriodEndDate := LeaseEndDate;

                        MergeSameSquare."MS_End Date" := PeriodEndDate;

                        // Calculate the number of days for this chunk
                        TotalDays := PeriodEndDate - PeriodStartDate + 1;
                        MergeSameSquare."MS_Number of Days" := TotalDays;

                        // Populate other fields
                        MergeSameSquare."MS_Merged Unit ID" := Rec."Unit Name";
                        MergeSameSquare."MS_Unit Sq Ft" := Rec."Unit Sq. Feet";

                        // Set default values for Rate per Sq.Ft and Annual Amount (to be manually entered)
                        MergeSameSquare."MS_Rate per Sq.Ft" := 0; // Initialize as 0; users will manually enter this
                        MergeSameSquare."MS_Annual Amount" := 0; // Calculated after manual input

                        // Set Final Annual Amount to match Annual Amount
                        MergeSameSquare."MS_Final Annual Amount" := MergeSameSquare."MS_Annual Amount";

                        // Calculate Per Day Rent
                        MergeSameSquare."MS_Per Day Rent" := 0; // Will be calculated after manual input

                        MergeSameSquare.Insert();

                        // Move to the next period
                        PeriodStartDate := PeriodEndDate + 1;
                        YearCounter += 1;
                        LineNoCounter += 1;
                    end;
                end


                else if "Merge Rent Calculation" = "Merge Rent Calculation"::"Merged Unit with lumpsum annual amount" then begin

                    if Rec."ID" = 0 then
                        Error('ID is missing or not assigned.');

                    LeaseProposal.Reset();
                    LeaseProposal.SetRange("ID", Rec."ID");

                    if not LeaseProposal.FindFirst() then
                        Error('No record found for ID %1.', Rec."ID");

                    // Delete existing records to avoid duplication
                    MergeLumSquare.SetRange("ID", LeaseProposal."ID");
                    if MergeLumSquare.FindSet() then
                        repeat
                            MergeLumSquare.Delete();
                        until MergeLumSquare.Next() = 0;

                    PeriodStartDate := LeaseProposal."Contract Start Date";
                    YearCounter := 1;
                    LineNoCounter := 1;

                    // Loop through years and create records
                    while PeriodStartDate <= LeaseProposal."Contract End Date" do begin
                        // Set the period start date for each year
                        MergeLumSquare.Init();
                        MergeLumSquare."ID" := LeaseProposal."ID";
                        MergeLumSquare."ML_Line No." := LineNoCounter;
                        MergeLumSquare.ML_Year := YearCounter;
                        MergeLumSquare."ML_Start Date" := PeriodStartDate;

                        // Default to 365 days, but check for leap years
                        DaysToAdd := 365; // Default to 365 days
                        LeapDays := 0;

                        // Check for leap years in the current period range
                        for CurrentYear := Date2DMY(PeriodStartDate, 3) to Date2DMY(PeriodStartDate + 364, 3) do begin
                            if IsLeapYear(CurrentYear) then begin
                                // Ensure the leap day (Feb 29) falls within the range
                                if (DMY2Date(29, 2, CurrentYear) >= PeriodStartDate) and
                                   (DMY2Date(29, 2, CurrentYear) <= PeriodStartDate + DaysToAdd - 1) then
                                    LeapDays += 1;
                            end;
                        end;

                        // Adjust DaysToAdd to account for any leap days
                        DaysToAdd := DaysToAdd + LeapDays;

                        // Calculate the period end date
                        PeriodEndDate := PeriodStartDate + DaysToAdd - 1;

                        // Ensure the period end date does not exceed the contract end date
                        if PeriodEndDate > LeaseProposal."Contract End Date" then
                            PeriodEndDate := LeaseProposal."Contract End Date";

                        MergeLumSquare."ML_End Date" := PeriodEndDate;

                        // Calculate the number of days for this period
                        TotalDays := PeriodEndDate - PeriodStartDate + 1;
                        MergeLumSquare."ML_Number of Days" := TotalDays;

                        // Populate fields with the unit and size from LeaseProposal
                        MergeLumSquare."ML_Merged Unit ID" := LeaseProposal."Unit Name";
                        MergeLumSquare."ML_Unit Sq Ft" := LeaseProposal."Unit Sq. Feet";

                        // For the first year, initialize the Annual Amount and Final Annual Amount
                        if YearCounter = 1 then begin
                            MergeLumSquare."ML_Annual Amount" := 0; // User will enter manually
                            MergeLumSquare."ML_Final Annual Amount" := 0;
                        end;

                        // Calculate Per Day Rent for the period (Annual Amount / Total Days)
                        if TotalDays > 0 then
                            MergeLumSquare."ML_Per Day Rent" := MergeLumSquare."ML_Final Annual Amount" / TotalDays
                        else
                            MergeLumSquare."ML_Per Day Rent" := 0;

                        MergeLumSquare.Insert();

                        // Move to the next year and update the line number
                        PeriodStartDate := PeriodEndDate + 1;
                        YearCounter += 1;
                        LineNoCounter += 1;
                    end; // End of the loop for years
                end


                else if "Merge Rent Calculation" = "Merge Rent Calculation"::"Merged Unit with differential square feet rate" then begin

                    // Delete existing records with the same "ID" and "MD_Line No."
                    MergeDiffSquare.SetRange("ID", Rec."ID");
                    if MergeDiffSquare.FindSet() then
                        repeat
                            MergeDiffSquare.Delete();  // Delete existing records to prevent duplicates
                        until MergeDiffSquare.Next() = 0;

                    // Initialize variables
                    PeriodStartDate := Rec."Contract Start Date";
                    LeaseEndDate := Rec."Contract End Date";
                    YearCounter := 1;
                    LineNoCounter := 1;

                    // Fetch data from the Sub Lease Merged Units table based on "ID"
                    SubLeaseMergeRec.SetRange("ID", Rec."ID");

                    // Loop through the Sub Lease Merged Units and fetch relevant data
                    if SubLeaseMergeRec.FindSet() then begin
                        repeat
                            // Loop through each year and create records
                            YearCounter := 1;
                            PeriodStartDate := Rec."Contract Start Date";
                            LeaseEndDate := Rec."Contract End Date";

                            // Loop to divide the period into yearly chunks and create records for each unit
                            while PeriodStartDate <= LeaseEndDate do begin
                                MergeDiffSquare.Init();
                                MergeDiffSquare."ID" := Rec."ID";  // Use "ID" here
                                MergeDiffSquare."MD_Line No." := LineNoCounter;
                                MergeDiffSquare.MD_Year := YearCounter;
                                MergeDiffSquare."MD_Start Date" := PeriodStartDate;

                                // Calculate the End Date (365 days after Start Date, adjusted for leap years)
                                DaysToAdd := 365; // Default to 365 days
                                LeapDays := 0;

                                // Check for leap years in the range from Start Date to Start Date + 364 days
                                for CurrentYear := Date2DMY(PeriodStartDate, 3) to Date2DMY(PeriodStartDate + 364, 3) do begin
                                    if IsLeapYear(CurrentYear) then begin
                                        // Ensure the leap day (Feb 29) falls within the range
                                        if (DMY2Date(29, 2, CurrentYear) >= PeriodStartDate) and
                                           (DMY2Date(29, 2, CurrentYear) <= PeriodStartDate + DaysToAdd - 1) then
                                            LeapDays += 1;
                                    end;
                                end;

                                // Adjust DaysToAdd to account for any leap days
                                DaysToAdd := DaysToAdd + LeapDays;

                                // Calculate the PeriodEndDate
                                PeriodEndDate := PeriodStartDate + DaysToAdd - 1;

                                // Ensure the End Date does not exceed the Lease End Date
                                if PeriodEndDate > LeaseEndDate then
                                    PeriodEndDate := LeaseEndDate;

                                MergeDiffSquare."MD_End Date" := PeriodEndDate;

                                // Calculate the number of days for this chunk
                                TotalDays := PeriodEndDate - PeriodStartDate + 1;
                                MergeDiffSquare."MD_Number of Days" := TotalDays;

                                // Populate other fields based on the Sub Lease Merged Units data
                                MergeDiffSquare."MD_Merged Unit ID" := Rec."Unit Name";
                                MergeDiffSquare."MD_Unit Sq Ft" := SubLeaseMergeRec."Unit Size"; // From Sub Lease Merged Units
                                MergeDiffSquare."MD_Unit ID" := SubLeaseMergeRec."Single Unit Name"; // From Sub Lease Merged Units

                                // Set default values for Rate per Sq.Ft and Annual Amount (to be manually entered)
                                MergeDiffSquare."MD_Rate per Sq.Ft" := 0; // Initialize as 0; users will manually enter this
                                MergeDiffSquare."MD_Annual Amount" := 0; // Calculated after manual input

                                // Set Final Annual Amount to match Annual Amount
                                MergeDiffSquare."MD_Final Annual Amount" := MergeSameSquare."MS_Annual Amount";

                                // Calculate Per Day Rent
                                MergeDiffSquare."MD_Per Day Rent" := 0;
                                // Will be calculated after manual input

                                MergeDiffSquare.Insert(); // Insert the record

                                // Move to the next period
                                PeriodStartDate := PeriodEndDate + 1;
                                YearCounter += 1;
                                LineNoCounter += 1;
                            end; // End of the while loop

                        until SubLeaseMergeRec.Next() = 0;
                    end
                    else
                        Error('No matching records found in Sub Lease Merged Units for the given ID.');

                end;
            end;

        }

        field(50162; "Single Unit Name"; Text[500])
        {
            DataClassification = ToBeClassified;
            Caption = 'Single Unit Names';
        }

        field(50163; "Rent VAT Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract VAT Amount';
            Editable = false;

            // trigger OnValidate()
            // begin
            //     "Rent VAT Amount" := "Annual Rent Amount" * ("Rent Amount VAT %" / 100);
            // end;
        }

        field(50164; "Rent Amount VAT %"; Option)
        {
            OptionMembers = "0%","5%";
            Caption = 'Contract Amount VAT %';
            Editable = false;

            // trigger OnValidate()
            // begin
            //     CalcVATAndTotalValue();
            // end;

        }

        field(50165; "Rent Amount Including VAT"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract Amount Including VAT';
            Editable = false;
            // trigger OnValidate()
            // begin
            //     "Rent Amount Including VAT" := "Annual Rent Amount" + "Rent VAT Amount";
            // end;

        }

        // Deposit and Fees Group
        // field(50166; "Security Deposit Amount"; Decimal)
        // {
        //     DataClassification = ToBeClassified;

        // }

        field(50142; "Security Deposit Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(50167; "Other Fees"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Other Fees ';
        }
        field(50168; "Refund Conditions"; Text[1000])
        {
            DataClassification = ToBeClassified;
        }

        // Responsibilities Group
        field(50169; "Maintenance Responsibilities"; Option)
        {
            OptionMembers = Tenant,Landlord;
            DataClassification = ToBeClassified;
        }
        field(50170; "Utility Bills Responsibility"; Option)
        {
            OptionMembers = Tenant,Landlord;
            DataClassification = ToBeClassified;
        }
        field(50171; "Insurance Requirements"; Text[250])
        {
            DataClassification = ToBeClassified;
        }

        // Conditions for Renewal Group

        field(50172; "Rent Escalation Clause"; Text[1000])
        {
            DataClassification = ToBeClassified;
        }

        // Special Conditions Group
        field(50173; "Early Termination Conditions"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(50174; "Restrictions"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(50175; "Legal Jurisdiction"; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Legal Jurisdiction (e.g., Dubai Courts)';
        }


        field(50184; "Vendor ID"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Vendor ID';

            trigger OnLookup()
            var
                VendorProfileRec: Record "Vendor Profile";
                AnnualAmount: Decimal;
            begin
                VendorProfileRec.SetRange("Vendor Category", 'Brokers and Commission Agent');
                VendorProfileRec.SetRange("Contract Status", "Contract Status"::"Active"); // 👈 Add this line
                if Page.RunModal(Page::"Vendor Profile List", VendorProfileRec) = Action::LookupOK then begin
                    "Vendor ID" := VendorProfileRec."Vendor ID";
                    "Vendor Name" := VendorProfileRec."Vendor Name";
                    "Start Date" := VendorProfileRec."Start Date";
                    "End Date" := VendorProfileRec."End Date";
                    "Contract Status" := VendorProfileRec."Contract Status";
                    "Calculation Method" := VendorProfileRec."Calculation Method";
                    "Percentage Type" := VendorProfileRec."Percentage Type";
                    Percentage := VendorProfileRec.Percentage;
                    "Base Amount Type" := VendorProfileRec."Base Amount Type";

                    case "Base Amount Type" of
                        "Base Amount Type"::"Annual Rent":
                            AnnualAmount := Rec."Rent Amount";
                        "Base Amount Type"::"Monthly Rent":
                            AnnualAmount := Rec."Rent Amount" / 12;
                    end;

                    Amount := AnnualAmount;
                    "Frequency Of Payment" := VendorProfileRec."Frequency Of Payment";
                end else begin
                    "Vendor ID" := '';
                    "Vendor Name" := '';
                    "Start Date" := 0D;
                    "End Date" := 0D;
                    "Contract Status" := "Contract Status"::" ";
                    "Calculation Method" := ' ';
                    "Percentage Type" := "Percentage Type"::" ";
                    Percentage := 0;
                    Amount := 0;
                    "Base Amount Type" := "Base Amount Type"::" ";
                    "Frequency Of Payment" := "Frequency Of Payment"::" ";
                end;
            end;
        }
        field(50185; "Vendor Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Vendor Name';
            Editable = false;
        }
        field(50186; "Percentage"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Percentage';
        }
        field(50187; "Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Amount';
        }
        // field(50188; "Percentage/Amount"; Decimal)
        // {
        //     DataClassification = ToBeClassified;
        //     Caption = 'Percentage/Amount';
        // }
        field(50176; "Calculation Method"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Calculation Method';
            TableRelation = "Calculation Type"."Calculation Type";
        }

        field(50177; "Percentage Type"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Percentage Type';
            OptionMembers = " ","Fixed","Variable";
        }
        field(50178; "Base Amount Type"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Base Amount Type';
            OptionMembers = " ","Revenue","Collection","Annual Rent","Monthly Rent";
        }
        field(50179; "Frequency Of Payment"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Frequency Of Payment';
            OptionMembers = " ","Monthly","Quaterly","Half Yearly","Yearly";
        }

        field(50180; "Start Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Start Date';
            Editable = false;
        }
        field(50181; "End Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'End Date';
            Editable = false;
        }

        field(50182; "ContractStatus"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract Status';
            OptionMembers = " ","Active","Terminate";
        }

        field(50183; "Is any Broker Involved?"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is any Broker Involved?';
        }




    }

    keys
    {
        key(PK; "Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Id", "Unit Name", "Property Name", "Tenant Full Name", "Tenant ID", "Unit Number")
        {

        }
    }

    //-------------Calculate Lease Duration---------------------//


    procedure CalculateLeaseDuration()
    var
        LeaseStartDate: Date;
        LeaseEndDate: Date;
        Years: Integer;
        Months: Integer;
        Days: Integer;
        DurationText: Text[50];
        TempStartDate: Date;
        DaysDifference: Integer;
    begin
        LeaseStartDate := "Contract Start Date";
        LeaseEndDate := "Contract End Date";

        if (LeaseStartDate <> 0D) and (LeaseEndDate <> 0D) then begin
            if LeaseEndDate >= LeaseStartDate then begin
                // Calculate total days difference
                DaysDifference := LeaseEndDate - LeaseStartDate + 1;

                // If the difference is exactly 365 or 366 days (accounting for leap year)
                if (DaysDifference = 365) or (DaysDifference = 366) then begin
                    Years := 1;
                    Months := 0;
                    Days := 0;
                end else begin
                    TempStartDate := LeaseStartDate;

                    // Calculate the years
                    Years := 0;
                    while (CALCDATE('<+1Y>', TempStartDate) <= LeaseEndDate) or
                          (CALCDATE('<+1Y-1D>', TempStartDate) = LeaseEndDate) do begin
                        TempStartDate := CALCDATE('<+1Y>', TempStartDate);
                        Years := Years + 1;
                    end;

                    // Calculate the months
                    Months := 0;
                    while CALCDATE('<+1M>', TempStartDate) <= LeaseEndDate do begin
                        TempStartDate := CALCDATE('<+1M>', TempStartDate);
                        Months := Months + 1;
                    end;

                    // Calculate the remaining days
                    Days := LeaseEndDate - TempStartDate + 1;
                end;

                // Build the duration text
                DurationText := '';
                if Years > 0 then
                    DurationText := Format(Years) + ' year(s) ';

                if Months > 0 then
                    DurationText := DurationText + Format(Months) + ' month(s) ';

                if Days > 0 then
                    DurationText := DurationText + Format(Days) + ' day(s)';

                "Contract Tenor" := DelChr(DurationText, '<>', ' ');
            end else
                "Contract Tenor" := '';
        end else
            "Contract Tenor" := '';
    end;

    // procedure CalculateLeaseDuration()
    // var
    //     LeaseStartDate: Date;
    //     LeaseEndDate: Date;
    //     Years: Integer;
    //     Months: Integer;
    //     Days: Integer;
    //     DurationText: Text[50];
    // begin
    //     LeaseStartDate := "Contract Start Date";
    //     LeaseEndDate := "Contract End Date";

    //     if (LeaseStartDate <> 0D) and (LeaseEndDate <> 0D) then begin
    //         if LeaseEndDate >= LeaseStartDate then begin
    //             // Calculate years, months, and days
    //             Years := Date2DMY(LeaseEndDate, 3) - Date2DMY(LeaseStartDate, 3);
    //             Months := Date2DMY(LeaseEndDate, 2) - Date2DMY(LeaseStartDate, 2);
    //             Days := Date2DMY(LeaseEndDate, 1) - Date2DMY(LeaseStartDate, 1);

    //             // Adjust for negative months
    //             if Months < 0 then begin
    //                 Years := Years - 1;
    //                 Months := Months + 12;
    //             end;

    //             // Adjust for negative days
    //             if Days < 0 then begin
    //                 Months := Months - 1;
    //                 Days := Days + (Date2DMY(CALCDATE('<+1M>', LeaseStartDate), 1) - Date2DMY(LeaseStartDate, 1));
    //             end;

    //             // Build the duration text
    //             DurationText := '';

    //             if Years > 0 then
    //                 DurationText := Format(Years) + ' year(s) ';

    //             if Months > 0 then
    //                 DurationText := DurationText + Format(Months) + ' month(s) ';

    //             if Days > 0 then
    //                 DurationText := DurationText + Format(Days) + ' day(s)';

    //             "Contract Tenor" := DelChr(DurationText, '<>', ' '); // Remove leading and trailing spaces
    //         end else
    //             "Contract Tenor" := ''; // Clear if the end date is before the start date
    //     end else
    //         "Contract Tenor" := ''; // Clear if either date is not set
    // end;

    //-------------Calculate Lease Duration---------------------//

    //-------------Leap year Counting--------------//
    local procedure IsLeapYear(Year: Integer): Boolean
    begin
        if (Year mod 4 = 0) and ((Year mod 100 <> 0) or (Year mod 400 = 0)) then
            exit(true);
        exit(false);
    end;

    //-------------Leap year Counting--------------//

    trigger OnDelete()
    var
    begin
        DeleteSingleUnitSameRate();
        DeleteMergeUnitSameRate();
        DeletePerDayRevenueUnitSameRate();
        DeleteLeaseMergeAllUnitDetails();
        DeleteMergeUnitDiffRate();
        DeleteSingleUnitLumpsumRate();
        DeleteMergeUnitLumpsumRate();

    end;

    procedure DeleteSingleUnitSameRate()
    var
        deleteSingleUnitRecords: Record "CR Single Unit Rent SubPage";

    begin
        deleteSingleUnitRecords.SetRange("ID", Rec."Proposal ID");

        if deleteSingleUnitRecords.FindSet() then begin
            deleteSingleUnitRecords.DeleteAll();
        end

    end;

    procedure DeleteMergeUnitSameRate()
    var
        deleteMergeUnitRecords: Record "CR Merge SameSqure SubPage";

    begin
        deleteMergeUnitRecords.SetRange("ID", Rec."Proposal ID");

        if deleteMergeUnitRecords.FindSet() then begin
            deleteMergeUnitRecords.DeleteAll();
        end

    end;

    procedure DeletePerDayRevenueUnitSameRate()
    var
        deletePerDayRevenueUnitRecords: Record "CR Per Day Rent for Revenue";

    begin
        deletePerDayRevenueUnitRecords.SetRange("Proposal Id", Rec."Proposal ID");

        if deletePerDayRevenueUnitRecords.FindSet() then begin
            deletePerDayRevenueUnitRecords.DeleteAll();
        end

    end;

    procedure DeleteLeaseMergeAllUnitDetails()
    var
        deleteAllUnitRecords: Record "CR Sub Lease Merged Units";

    begin
        deleteAllUnitRecords.SetRange("ID", Rec."Proposal ID");

        if deleteAllUnitRecords.FindSet() then begin
            deleteAllUnitRecords.DeleteAll();
        end

    end;

    procedure DeleteMergeUnitDiffRate()
    var
        deleteMergeUnitDiffRecords: Record "CR Merge DifferentSq SubPage";

    begin
        deleteMergeUnitDiffRecords.SetRange("ID", Rec."Proposal ID");

        if deleteMergeUnitDiffRecords.FindSet() then begin
            deleteMergeUnitDiffRecords.DeleteAll();
        end

    end;

    procedure DeleteMergeUnitLumpsumRate()
    var
        deleteMergeUnitLumpsumRecords: Record "CR Merge LumAnnualAmount SP";

    begin
        deleteMergeUnitLumpsumRecords.SetRange("ID", Rec."Proposal ID");

        if deleteMergeUnitLumpsumRecords.FindSet() then begin
            deleteMergeUnitLumpsumRecords.DeleteAll();
        end

    end;

    procedure DeleteSingleUnitLumpsumRate()
    var
        deleteSingleUnitLumpsumRecords: Record "CR Single LumAnnualAmnt SP";

    begin
        deleteSingleUnitLumpsumRecords.SetRange("ID", Rec."Proposal ID");

        if deleteSingleUnitLumpsumRecords.FindSet() then begin
            deleteSingleUnitLumpsumRecords.DeleteAll();
        end

    end;






}