




declare @startdate date
declare @enddate date
set @startdate='20230601'
set @enddate='20230630'



--set @startdate =DATEADD(month,DATEDIFF(month,0,getdate()-1),0)
--set @enddate  = DATEADD(MONTH,DATEDIFF(MONTH,-1,GETDATE()-1),-1)

--select @startdate, @enddate

select 
Pointstobecredit.*,
isnull(additional.[Additional Rewarded PB Points],0) 'Additional Reward Credited',
isnull(Total_credited.[Total PB Points Credited],0)'Total points Credited',
isnull((Pointstobecredit.[Total Payback Points To Be Created To Customer As Per Logic ]+additional.[Additional Rewarded PB Points])-Total_credited.[Total PB Points Credited],0) as Difference ,
isnull(reversed.reversed,0)'Reversed from customers',
isnull(notreversed.reversed,0)'Not Reversed from customers'



from (
select 
l.MobileNo as 'Mobile No',
l.Customer_id as 'Customer ID',
concat(l.FirstName, ' ', l.LastName) as 'Name',
isnull(sum(case when  t.trans_type=1818  and  cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end),0) as 'Wallet Recharge Amount 23' ,
isnull(sum(case when  t.trans_type=1818  and  cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.payback_points end),0) as  'Payback Points against Wallet Recharge As Per Logic (3 PB Points Per 100/-)',
--isnull(cast((sum(case when t.trans_type=1818  and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)/100)*3 as int),0) as 'Payback Points against Wallet Recharge As Per Logic (3 PB Points Per 100/-)' ,

isnull(sum(case when t.trans_type=1820  and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end),0) as 'Wallet Sale Amount MARCH 23',
isnull(sum(case when t.Trans_Type=1820 and cast(transaction_date as date)>=@startdate and cast(transaction_date as date)<=@enddate then t.payback_points end),0) as 'Payback Points against Wallet Sale As Per Logic (1 PB Points Per 100/-)' ,
--isnull(cast((sum(case when t.trans_type=1820  and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)/100) as int),0) as 'Payback Points against Wallet Sale As Per Logic (1 PB Points Per 100/-)' ,

isnull(sum(case when t.trans_type=1801  and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end),0) as 'Direct Sale Amount MARCH 23',
isnull(sum(case when t.trans_type=1801 and cast(t.Transaction_Date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.payback_points end),0)as 'Payback Points against direct Sale As Per Logic (4 PB Points Per 100/-)' ,
--isnull(cast((sum(case when t.trans_type=1801 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)/100)*4 as int),0) as 'Payback Points against direct Sale As Per Logic (4 PB Points Per 100/-)' ,

isnull(sum(case when t.trans_type=1868 and  cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end),0) as 'Fastag Sale Amount MARCH 23',
isnull(sum(case when t.trans_type=1868 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.payback_points end),0) as 'Payback Points against Fastag Sale As Per Logic (4 PB Points Per 100/-)' ,

--isnull(cast((sum(case when t.trans_type=1868  and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)/100)*4 as int),0) as 'Payback Points against Fastag Sale As Per Logic (4 PB Points Per 100/-)' ,

(
isnull(sum(case when  t.trans_type=1818  and  cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.payback_points end),0)
+
isnull(sum(case when t.Trans_Type=1820 and cast(transaction_date as date)>=@startdate and cast(transaction_date as date)<=@enddate then t.payback_points end),0)       
+
isnull(sum(case when t.trans_type=1801 and cast(t.Transaction_Date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.payback_points end),0)   
+
isnull(sum(case when t.trans_type=1868 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.payback_points end),0)           




--isnull(cast((sum(case when t.trans_type=1818 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)/100)*3 as int),0)
--+
--isnull(cast((sum(case when t.trans_type=1820 and  cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)/100) as int),0) 
--+
--isnull(cast((sum(case when t.trans_type=1801 and  cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)/100)*4 as int),0) 
--+
--isnull(cast((sum(case when t.trans_type=1868 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)/100)*4 as int),0)

) as 'Total Payback Points To Be Created To Customer As Per Logic '

from trans t(nolock)
join loyaluser l (nolock) on t.customer_id=l.customer_id	
--left join tbl_PaybackEarn_HPPay pe (nolock) on t.Raw_Transaction_Id=pe.Raw_Transaction_Id
--left join tbl_PaybackEarn_HPPay_Reversal_24Mar2023_backup pr (nolock) on t.TransactionId=pr.TransactionId 

--where l.Customer_id=1014726785          --1100009874
group by 
l.MobileNo,
l.Customer_id,
concat(l.FirstName, ' ', l.LastName)
--Order by
--[Wallet Recharge Amount MARCH 23] desc

having 
--sum(case when t.trans_type=1818 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end)>0
isnull(sum(case when t.trans_type=1818 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end),0)>0 or
isnull(sum(case when t.trans_type=1820 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end),0)>0 or
isnull(sum(case when t.trans_type=1801 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end),0)>0 or
isnull(sum(case when t.trans_type=1868 and cast(t.transaction_date as date)>=@startdate and cast(t.transaction_date as date)<=@enddate then t.amount end),0)>0 
) as Pointstobecredit

left join 


(
select 
l.MobileNo as 'Mobile No',
l.Customer_id as 'Customer ID',

isnull(sum(case when  pe.TransSource=415 and pe.status_flag=0 and pe.trans_type in (1818,1820,1801,1868) and
cast(pe.TxnDateTime as date)>=@startdate and cast(pe.TxnDateTime as date)<=@enddate then pe.PaybackPointCredited end),0)  as 'Additional Rewarded PB Points'



from trans t(nolock)
join loyaluser l (nolock) on t.customer_id=l.customer_id	
join tbl_PaybackEarn_HPPay pe (nolock) on t.Raw_Transaction_Id=pe.Raw_Transaction_Id and t.customer_id=pe.customer_id

--where l.Customer_id=1000070361          --1100009874

group by 
l.MobileNo,
l.Customer_id
) as additional

on Pointstobecredit.[Customer ID]=additional.[Customer ID]

left join

(
select 
l.MobileNo as 'Mobile No',
l.Customer_id as 'Customer ID',
--t.Raw_Transaction_Id ,
isnull(sum(case when pe.status_flag=0 and pe.trans_type in (1818,1820,1801,1868) and t.trans_type in (1818,1820,1801,1868)  and
cast(pe.TxnDateTime as date)>=@startdate and cast(pe.TxnDateTime as date)<=@enddate then pe.PaybackPointCredited end),0) as 'Total PB Points Credited'



from trans t(nolock)
join loyaluser l (nolock) on t.customer_id=l.customer_id	
join tbl_PaybackEarn_HPPay pe (nolock) on t.Raw_Transaction_Id=pe.Raw_Transaction_Id and t.customer_id=pe.customer_id
--left join tbl_PaybackEarn_HPPay_Reversal_24Mar2023_backup pr (nolock) on t.TransactionId=pr.TransactionId 

where  t.Raw_Transaction_Id !=0--) as additional          --1100009874

group by 
l.MobileNo,
l.Customer_id
) as Total_credited

on Pointstobecredit.[Customer ID]=Total_credited.[Customer ID]

left join
(
select customer_id,
isnull(sum(reversedpoints),0) as reversed
from tbl_PaybackEarn_HPPay_Reversal_24Mar2023_backup (nolock)
where cast(txndatetime as date)>=@startdate and cast(txndatetime as date)<=@enddate and status_flag=0
group by customer_id)as reversed

on Pointstobecredit.[Customer ID]=reversed.Customer_Id

--where Pointstobecredit.[Customer ID]=1000070361
left join
(
select customer_id,
isnull(sum(PaybackPointCredited),0) as reversed
from tbl_PaybackEarn_HPPay_Reversal_24Mar2023_backup (nolock)
where cast(txndatetime as date)>=@startdate and cast(txndatetime as date)<=@enddate and status_flag=1
group by customer_id)as notreversed

on Pointstobecredit.[Customer ID]=notreversed.Customer_Id

