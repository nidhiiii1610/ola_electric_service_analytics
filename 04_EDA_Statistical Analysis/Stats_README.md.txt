
Phase 3:-  EDA & Statistical Analysis

This one workbook contains all worksheets/tabs for all tasks of phase 3.
https://drive.google.com/drive/folders/11TnMw1ueoEimKA2FFi-c_UZO3x1RQ-Ki?usp=sharing

Task 
Compute complaints per 1,000 vehicles and vehicles per active service centre
monthly - the two structural-gap metrics

| Average of complaints per 1000 vehicle- 2023 | 52.6   |
| --------------------------------------------- | ------ |
| Average of complaints per 1000 vehicle- 2024  | 13.0   |
| Vehicles per Active Service Centre 2023       | 463.0  |
| Vehicles per Active Service Centre 2024       | 1194.1 |

The structural service-capacity gap is clearly visible:

Vehicles per active service centre increased from 463  to 1,194.
That's about 2.6 times higher vehicle load per centre in 2024.
So, even though complaints per 1,000 vehicles were lower on average, each service centre was supporting a much larger vehicle population.

To determine whether the average daily vehicle sales changed significantly after the October 2024 CCPA notice.


Task -
Hypothesis test (Excel Data Analysis ToolPak): two-sample t-test on mean daily
sales before vs after the October 2024 CCPA notice; state H0, H1, p-value and conclusion

Two-Sample t-Test: Daily Sales Before vs After October 2024 CCPA Notice

1. Objective

To determine whether the average daily vehicle sales changed significantly after the October 2024 CCPA notice

We compared:

* Daily units sold before the CCPA notice
* Daily units sold after the CCPA notice



2. Data Used

Variables:

`sale_date` - date of sale
 `daily_units_sold` - number of vehicles sold per day
`period` - identifies the observations as Before or After the CCPA notice

The daily sales data was divided into two groups:

Before CCPA
After CCPA

---

3. Hypotheses

 H0 - Null Hypothesis

The mean daily sales before and after the October 2024 CCPA notice are equal

H1 - Alternative Hypothesis

The mean daily sales before and after the October 2024 CCPA notice are different.

This is a two-tailed test because we are testing whether sales changed in either direction.

---

4. Significance Level

We selected a significance level of:

 = 0.05 (5%)

This means we use 0.05 as the decision threshold

Decision rule:

p-value < 0.05 - Reject H0
p-value >= 0.05 - Fail to reject H0

The 5% level was selected as the standard threshold for statistical significance.

5. Statistical Test

Test Used

Two-Sample t-Test Assuming Unequal Variances

We used the unequal-variance version because we did not assume that the variation in daily sales was the same before and after the CCPA notice.

In Excel Online, the p-value was calculated using:

T.TEST(Before Sales Range, After Sales Range, 2, 3)`

Where:

 `2` = two-tailed test
 `3` = two-sample unequal variance


6. Result

p-value = 6.95995E-13

This is approximately:

0.000000000000696

Comparison:
6.95995E-13 < 0.05

Therefore, the result is statistically significant

 7. Conclusion

Since the p-value is much smaller than 0.05:

Reject H0

There is statistically significant evidence that the mean daily sales changed after the October 2024 CCPA notice

However, the t-test alone does not prove that the CCPA notice caused the change. It only shows that the average daily sales before and after the notice were statistically different.

