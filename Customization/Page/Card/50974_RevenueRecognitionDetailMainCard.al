page 50974 "Revenue Recognition Detail Sub"
{

    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Revenue Recognition Details";
    Caption = 'Revenue Recognition Details';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Entry No.';
                    Visible = false;
                }
                field("Item Type"; Rec."Item Type")
                {
                    ApplicationArea = All;
                }
                field("Property Name"; Rec."Property Name")
                {
                    ApplicationArea = All;
                }
                field("Single Unit Names"; Rec."Single Unit Names")
                {
                    ApplicationArea = All;
                }
                field("Contract Id"; Rec."Contract Id")
                {
                    ApplicationArea = All;
                }
                field("Contract Tenure"; Rec."Contract Tenure")
                {
                    ApplicationArea = All;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field("Contract Start Date"; Rec."Contract Start Date")
                {
                    ApplicationArea = All;
                }
                field("Contract End Date"; Rec."Contract End Date")
                {
                    ApplicationArea = All;
                }
                field("Grace Days"; Rec."Grace Days")
                {
                    ApplicationArea = All;
                }
                field("Grace Start Date"; Rec."Grace Start Date")
                {
                    ApplicationArea = All;
                }
                field("Grace End Date"; Rec."Grace End Date")
                {
                    ApplicationArea = All;
                }
                field("Termination Date"; Rec."Termination Date")
                {
                    ApplicationArea = All;
                }
                field("Suspension Start Date"; Rec."Suspension Start Date")
                {
                    ApplicationArea = All;
                }
                field("Suspension End Date"; Rec."Suspension End Date")
                {
                    ApplicationArea = All;
                }
                field("Multi Year Start Date"; Rec."Multi Year Start Date")
                {
                    ApplicationArea = All;
                }
                field("Multi Year End Date"; Rec."Multi Year End Date")
                {
                    ApplicationArea = All;
                }
                field("Contract Amount"; Rec."Contract Amount")
                {
                    ApplicationArea = All;
                }
                field("Annual Amount"; Rec."Annual Amount")
                {
                    ApplicationArea = All;
                }
                field("Posting Month"; Rec."Posting Month")
                {
                    ApplicationArea = All;
                }
                field("Posting Year"; Rec."Posting Year")
                {
                    ApplicationArea = All;
                }
                field("Posting Period"; Rec."Posting Period")
                {
                    ApplicationArea = All;
                }
                field("Final Annual Amount"; Rec."Final Annual Amount")
                {
                    ApplicationArea = All;
                }
                field("No Of Days"; Rec."No Of Days")
                {
                    ApplicationArea = All;
                }
                field("Per Day Rent"; Rec."Per Day Rent")
                {
                    ApplicationArea = All;
                }
                field("Per Month Rent"; Rec."Per Month Rent")
                {
                    ApplicationArea = All;
                }
                field("Total Value"; Rec."Total Value")
                {
                    ApplicationArea = All;
                }
                field("Owner Name"; Rec."Owner Name")
                {
                    ApplicationArea = All;
                }
                field("Owner Share"; Rec."Owner Share")
                {
                    ApplicationArea = All;
                }
            }
            // group(" ")
            // {
            //     field("Total Amount"; totalamounts)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Total Amount';
            //         Editable = false;
            //     }
            //     field("Total Contract Amount"; totalcontractAmounts)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Total Contract Amount';
            //         Editable = false;
            //     }
            // }

            // group("Final Amount")
            // {
            //     field("Total Amounts"; totalcombineamounts)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Total Amount';
            //         Editable = false;
            //     }
            //     field("Total Contract Amounts"; totalcombinecontractAmounts)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Total Contract Amount';
            //         Editable = false;
            //     }
            // }
        }
    }


    // procedure CalculateAndStoreTotalRevenue()
    // var
    //     revenueItemLine: Record "Revenue Recognition Details";
    //     revenueAllocLine: Record "Revenue Allocation Subgrid";
    // begin
    //     Clear(totalcontractAmounts);
    //     Clear(totalamounts);

    //     revenueItemLine.SetRange("RR_No.", RRID);
    //     if revenueItemLine.FindSet() then
    //         repeat
    //             totalcontractAmounts += revenueItemLine."Contract Amount";
    //             totalamounts += revenueItemLine."Total Value";
    //         until revenueItemLine.Next() = 0;


    //     revenueAllocLine.SetRange("Header No.", RRID);
    //     if revenueAllocLine.FindSet() then
    //         repeat
    //             totalcontractAmount += revenueAllocLine."Contract Amount";
    //             totalamount += revenueAllocLine."Total Value";
    //             totalannualamount += revenueAllocLine."Annual Amount";
    //             totalfinalannualamount += revenueAllocLine."Final Annual Amount";
    //         until revenueAllocLine.Next() = 0;


    //     totalcombinecontractAmounts := totalcontractAmount + totalcontractAmounts;
    //     totalcombineamounts := totalamount + totalamounts;
    // end;

    procedure SetRIID(pRRID: Integer)
    begin
        RRID := pRRID;

    end;


    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin

        Rec."RR_No." := RRID;
        // CalculateAndStoreTotalRevenue();
    end;

    // trigger OnAfterGetCurrRecord()
    // begin
    //     CalculateAndStoreTotalRevenue();
    // end;

    var
        RRID: Integer;

    //     totalcontractAmount: Decimal;
    //     totalamount: Decimal;
    //     totalannualamount: Decimal;
    //     totalfinalannualamount: Decimal;

    //     totalcontractAmounts: Decimal;
    //     totalamounts: Decimal;

    //     totalcombinecontractAmounts: Decimal;
    //     totalcombineamounts: Decimal;
}