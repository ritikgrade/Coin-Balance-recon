

use HPPAYProd

declare @startdate date = '20230701'--cast(getdate()-1 as date)
declare @enddate date ='20230801'--cast(getdate() as date)
declare @prev_start date ='20230203'
declare @prev_end date = @startdate


select *,(Settled_next+Settled_prev+Additional)as overall_diff,(case when Points=Diff then 'Transaction is not Settled' when glnot=Diff then 'GL Was not created that time'
			when (Settled_next+Settled_prev+Additional)=Diff then 'Difference amount is settled next month or settled from previous month or it is from Cobranded transaction that is processed in september '
			else '' end ) as Remark 

from ( 
select 
Cust ,
--@startdate				as Date,
sum([Opening balance]		)as [Opening],
sum(0						)as [Redeem reversal],
sum([Total credit]			)as [Credit],
sum([Total credit]			)as [Total Credit],
sum(0						)as [Credit Reversal],
sum([Total debit]			)as [Debit],

sum([Total debit]			)AS [Total debit],
sum([Total Credit])+sum([Total debit]) as [Net Posting],
sum([Opening balance])+sum([Total credit])+sum([Total debit]) as [Calculated],
sum([Closing Balance]) as Closing,
(sum([Opening balance])+sum([Total credit])+sum([Total debit])-(sum([Closing Balance]))) as Diff,
sum(Settled_next) as Settled_next,
sum(-settled_prev)as Settled_prev,
sum(-Additional)as Additional,
sum(points) as Points,
sum(gl_not_created) as glnot


from (
select 
	l.Customer_Id  as Cust,
	l.MobileNo,
	ISNULL(opening,0) AS [Opening balance], 
	ISNULL(Add_SALE.Earn,0) as  [Total credit],
	ISNULL(Add_SALE.Redemption,0) as[Total debit],
	--ISNULL(Add_SALE.[net posting],0) as [Net Posting],
	--ISNULL(opening+add_sale.[net posting],0) as [Calculated Closing Balance],
	ISNULL(closing,0) as [Closing Balance],
	isnull(Add_SALE_next.Settled_next,0) as Settled_next ,
	isnull(Add_SALE_prev.Settled_prev,0) as Settled_prev,
	isnull(additional.additional,0) as Additional,
	isnull(remark.points,0)as points,
	isnull(GL_not_created.ol,0)as gl_not_created

	--ISNULL((opening+add_sale.[net posting])-closing,0)as Diff
  
 from (select distinct Customer_id,MobileNo from loyaluser  (nolock))as l
 left join 
--OP
(
select Customer_Id, opening  from (
select * from (
select Customer_Id,ROW_NUMBER() over (partition by customer_id order by created_on desc) as rankk,Current_Balance as opening

from Tbl_General_Ledger_Audit_Happy_Coins (nolock) where cast(Created_On as date)<@startdate
) as d
where d.rankk=1) as op

union
select customer_id,opening from (
select distinct customer_id, 0 as  opening 
from Tbl_General_Ledger_Audit_Happy_Coins (nolock) where Customer_Id not in 
(select distinct  Customer_Id from Tbl_General_Ledger_Audit_Happy_Coins (nolock) where cast(Created_On as date)<@startdate) and  cast(Created_on as date)=@startdate
) AS D
) as Openn
on l.Customer_id=Openn.Customer_Id

left join 

--Add Sale
(
select customer_id--,count(transactionid)
,sum(case when trans_type in (1820,1801,1818,1868,1885,1886,1884) then payback_points end)  as Earn ,
sum(case when trans_type in (1883,1882)then -payback_points end ) as Redemption
from (
select customer_id, transactionid,payback_points,trans_type from trans 
where trans_type in (1820,1801,1818,1868,1885,1886,1883,1882) --and transaction_for=502 or transaction_for is null
and cast(Createdon as date)>=@startdate and cast(Createdon as date)<@enddate
union
select customer_id, hc.transaction_id,points_allocated,trans_type from tbl_honda_earn ha left join 
tbl_happycoins hc on hc.raw_transaction_id=ha.requestid  where requeststatus=3804 
and cast(hc.created_on as date)>=@startdate and cast(hc.created_on as date)<@enddate
--union
--select customer_id, transaction_id,points_allocated,trans_type from tbl_happycoins hc 
--where cast(hc.created_on as date)>=@startdate and cast(hc.created_on as date)<@enddate and trans_source=415 and trans_type in (1818,1801) and status_flag=0
) as h group by customer_id
) as Add_SALE
ON l.Customer_Id=Add_SALE.Customer_Id
LEFT JOIN 



--C
(
select Customer_Id,closing from (
select * from (
select Customer_Id,ROW_NUMBER() over (partition by customer_id order by created_on desc,transaction_id desc) as rankk,Current_Balance as closing

from Tbl_General_Ledger_Audit_Happy_Coins (nolock) where cast(Created_On as date)<@enddate
) as d
where d.rankk=1) as cl) AS closing
on closing.Customer_Id=l.Customer_Id 
left join


(
select txn.customer,sum(txn.Earn)as Earn,sum(Redemption) as Redemption,sum(dd.PA)as Settled_next


from (
select customer_id as customer,transactionid AS TXNID
,sum(case when trans_type in (1820,1801,1818,1868,1885,1886,1884) then payback_points end)  as Earn ,
sum(case when trans_type in (1883,1882)then -payback_points end ) as Redemption
from (
select customer_id, transactionid,payback_points,trans_type from trans 
where trans_type in (1820,1801,1818,1868,1885,1886,1883,1882) --and transaction_for=502 or transaction_for is null
and cast(createdon as date)>=@startdate and cast(createdon as date)<@enddate
union
select customer_id, hc.transaction_id,points_allocated,trans_type from tbl_honda_earn ha left join 
tbl_happycoins hc on hc.raw_transaction_id=ha.requestid  where requeststatus=3804 
and cast(hc.created_on as date)>=@startdate and cast(hc.created_on as date)<@enddate
--union
--select customer_id, transaction_id,points_allocated,trans_type from tbl_happycoins hc 
--where cast(hc.created_on as date)>=@startdate and cast(hc.created_on as date)<@enddate and trans_source=415 and trans_type in (1818,1801,1868) and status_flag=0
) as h group by customer_id,transactionid
) as txn
join 
(
select gl.TRANSACTION_ID,gl.points_allocated as PA,h.Trans_Source from Tbl_General_Ledger_Audit_Happy_Coins gl (nolock) 
join Tbl_HappyCoins h on h.Transaction_Id=gl.Transaction_Id and month(h.Created_On)>7  where month(gl.created_on)>7
) as dd
on dd.transaction_id=txn.TXNID and Trans_Source!=415
group by customer

) as Add_SALE_next
ON l.Customer_Id=add_sale_next.Customer

left join


(
select txn.customer,sum(txn.Earn)as Earn,sum(Redemption) as Redemption,sum(dd.PA)as Settled_prev


from (
select customer_id as customer,transactionid AS TXNID
,sum(case when trans_type in (1820,1801,1818,1868,1885,1886,1884) then payback_points end)  as Earn ,
sum(case when trans_type in (1883,1882)then -payback_points end ) as Redemption
from (
select customer_id, transactionid,payback_points,trans_type from trans 
where trans_type in (1820,1801,1818,1868,1885,1886,1883,1882) --and transaction_for=502 or transaction_for is null
and cast(Createdon as date)>=@prev_start and cast(Createdon as date)<@prev_end
union
select customer_id, hc.transaction_id,points_allocated,trans_type from tbl_honda_earn ha left join 
tbl_happycoins hc on hc.raw_transaction_id=ha.requestid  where requeststatus=3804 
and cast(hc.created_on as date)>=@prev_start and cast(hc.created_on as date)<@prev_end
--union
--select customer_id, transaction_id,points_allocated,trans_type from tbl_happycoins hc 
--where cast(hc.created_on as date)>=@prev_start and cast(hc.created_on as date)<@prev_end and trans_source=415 and trans_type in (1818,1801) and status_flag=0
) as h group by customer_id,transactionid
) as txn
join 
(
select gl.TRANSACTION_ID,gl.points_allocated as PA,h.Trans_Source from Tbl_General_Ledger_Audit_Happy_Coins gl (nolock) 
join tbl_happycoins h on h.Transaction_Id=gl.Transaction_Id and MONTH(h.Created_On)=7   where month(gl.created_on)=7
) as dd
on dd.transaction_id=txn.TXNID and dd.Trans_Source!=415
group by customer

) as Add_SALE_prev

on Add_SALE_prev.customer=l.customer_id
left join 

(select Customer_Id,sum(Points_Allocated) as additional from (
select customer_id, transaction_id,points_allocated,trans_type from tbl_happycoins hc 
where cast(hc.created_on as date)>=@startdate and cast(hc.created_on as date)<@enddate and trans_source=415 and trans_type in (1818,1801,1868) and status_flag=0
)as h group by Customer_Id ) as additional
on additional.Customer_Id=l.Customer_id
 left join
(
select customer_id ,sum(payback_points) as points, 'Transaction is not Settled' as Remark from trans 
where trans_type in (1820,1801,1818,1868) --and transaction_for=502 or transaction_for is null
and cast(createdon as date)>=@startdate and cast(createdon as date)<@enddate and Is_settled=0 group by customer_id
) as remark
on l.Customer_id=remark.Customer_Id
left join
(
select jk.* from (
select customer_id,sum(Points_Allocated) as ol from Tbl_General_Ledger_Audit_Happy_Coins where cast(Created_On as date)>=@startdate and cast(Created_On as date)<@enddate 
group by Customer_Id having  sum(Points_Allocated)>0 and sum(Current_Balance)=0) as jk
join Tbl_General_Ledger_Happy_Coins glhc on glhc.Customer_Id=jk.Customer_Id and glhc.Created_On>=@enddate
) as GL_not_created
on GL_not_created.Customer_Id=l.Customer_id

) as dump
group by Cust
) as h
WHERE H.Calculated<>h.Closing 
--and 
--Cust=1014059300



--where dump.[Total credit]>0 or dump.[Total debit]<>0
