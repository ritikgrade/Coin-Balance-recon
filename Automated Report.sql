use hppayprod
--		***** LPG DISTRIBUTIONS
        
DECLARE @REPORTDATE DATE        
DECLARE @STARTDATE DATE        
DECLARE @ENDDATE DATE        
SET @REPORTDATE= CAST(GETDATE() AS DATE)        
SET @STARTDATE = CASE WHEN DATEPART(DAY,@REPORTDATE)=1        
                 THEN DATEADD(MONTH,-1,@REPORTDATE)        
     ELSE DATEADD(MM,DATEDIFF(MM,0,@REPORTDATE),0) END        
SET @ENDDATE = @REPORTDATE        
        
--SELECT @REPORTDATE,@STARTDATE,@ENDDATE        
Set Nocount on;        
        
SELECT        
DISTINCT        
Isnull(Z.ZOName,'') AS MERCHANTZO,        
Isnull(R.ROName,'')AS MERCHANTRO,        
s.Store_Code AS DISTRIBUTERCODE,        
s.Store_Name AS DISTRIBUTERNAME,        
T.TransactionId AS TRANSACTIONID,        
T.Transaction_Date AS TRANSACTIONDATE,      
ts.Settlement_Date as SETTLEMENTDATE,    
L.Customer_id AS CUSTOMERCODE,        
(isnull(L.FirstName,'')+' '+isnull(L.LastName,'')) AS CUSTOMERNAME,        
L.MobileNo AS MOBILENO,        
p.trans_source AS SOURCE,        
'LPG DOMESTIC' AS SERVICENAME,        
CAST(t.Amount as FLOAT) as TransactionAmount        
FROM     
(select * from trans(nolock)
where Trans_Type IN (1801,1820,1874,1869) AND Is_settled=1    
AND CAST(Transaction_Date as date)>=@STARTDATE AND CAST(Transaction_Date as date)<@ENDDATE   
)t

--Trans t with(Nolock)    
inner join Mst_Stores s with(Nolock) on s.Store_Id=t.Store_id and t.Transaction_For=503    
Inner join loyaluser l with(Nolock) on l.Customer_id=t.Customer_Id    
Left join tbl_Trans_Settlement ts with(nolock) on ts.Terminal_Id=t.TerminalId and ts.BatchId=t.BatchId    
Left join Mst_trans_source p with(nolock) on p.Code=t.Trans_Source    
Left join Mst_zonaloffices z with(Nolock) on z.ZOCode=s.ZOCode    
Left join Mst_Regionaloffices r with(Nolock) on r.ROCode=s.ROCode    
      
--WHERE         
        
--T.Trans_Type IN (1801,1820,1874) AND t.Is_settled=1    
--AND CAST(t.Transaction_Date as date)>=@STARTDATE AND CAST(t.Transaction_Date as date)<@ENDDATE   
order by t.transaction_date     
        