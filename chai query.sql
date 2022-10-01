SELECT u.customer_id
	 , segment
     , CASE WHEN (YEAR(now()) - YEAR(birthday) + 1) >= 100 THEN MIN(age_avg)
		ELSE YEAR(now()) - YEAR(birthday) + 1
        END age
	 , gender
     , COUNT(CASE WHEN type = 'cb' THEN 1 END) cb # 캐시백 구매 건 수
     , COUNT(CASE WHEN type = 'dc' AND DATE_FORMAT(created_at, "%Y-%m-%d") < '2020-01-02' THEN 1 END) p1_dc # p1 할인 구매 건 수
	 , COUNT(CASE WHEN type = 'dc + cb' THEN 1 END) 'dc + cb' # 할인 + 캐시백 구매 건 수
	 , COUNT(CASE WHEN type = 'n.a' AND DATE_FORMAT(created_at, "%Y-%m-%d") < '2020-01-02' THEN 1 END) 'p1_n.a' # p1 비할인 구매 건 수
     , COUNT(CASE WHEN type = 'dc' AND DATE_FORMAT(created_at, "%Y-%m-%d") >= '2020-01-02' THEN 1 END) p2_dc # p2 할인 구매 건 수
	 , COUNT(CASE WHEN type = 'n.a' AND DATE_FORMAT(created_at, "%Y-%m-%d") >= '2020-01-02' THEN 1 END) 'p2_n.a' # p2 비할인 구매 건 수
	 , push_permission
     , frequency
     , monetary
     , AVG(time_diff) avg_time_diff # 구매 텀
     , SUM(CASE WHEN discount_amount != 0 THEN discount_amount END) avg_dc # 
     , SUM(CASE WHEN cashback_amount != 0 THEN discount_amount END) avg_cb # 
     , MIN(sign_up_date) sign_up_date
FROM
	users u
		INNER JOIN 
		(
		SELECT customer_id
			 , created_at
			 , post_discount
			 , cashback_amount
			 , discount_amount
			 , push_permission
			 , gender
			 , birthday
			 , sign_up_date
			 , type
			 , last_pc
			 , TIMESTAMPDIFF(SECOND, last_pc, created_at) time_diff # created_at - 이전 결제일 
             , age_avg
		FROM 
			( # 나이, 이전 결제일 컬럼 생성한 log 테이블
			 SELECT *
				  , (SELECT AVG(YEAR(now()) - YEAR(birthday) + 1) FROM log) AS age_avg
				  , LAG(created_at, 1) OVER(PARTITION BY customer_id ORDER BY created_at) last_pc # 이전 결제일
		  FROM log
          ) sub
			) AS l
        ON u.customer_id = l.customer_id
GROUP BY u.customer_id, gender, push_permission