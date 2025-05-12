/* Step 1: Import Data */
PROC IMPORT OUT=WORK.Healthcare 
            DATAFILE= "C:\Users\ysawant1\Desktop\SAS PROJECT\Healthcare Data.xlsx" 
            DBMS=EXCEL REPLACE;
    RANGE="'Healthcare Data$'"; 
    GETNAMES=YES;
    MIXED=NO;
    SCANTEXT=YES;
    USEDATE=YES;
    SCANTIME=YES;
RUN;

/* Step 2: Data Cleaning and Transformation */
DATA HealthcareClean;
    SET Healthcare;

    /* Encode categorical variables as binary */
    Gender_bin            = (Gender = "Male");
    Family_History_bin    = (Family_History = "Yes");
    Radiation_bin         = (Radiation_Exposure = "Yes");
    Iodine_Def_bin        = (Iodine_Deficiency = "Yes");
    Smoking_bin           = (Smoking = "Yes");
    Obesity_bin           = (Obesity = "Yes");
    Diabetes_bin          = (Diabetes = "Yes");

    /* Binary encoding of target variable */
    IF Thyroid_Cancer_Risk = "High" THEN Risk = 1;
    ELSE Risk = 0;
RUN;

/* Step 3: Descriptive Statistics */
PROC MEANS DATA=HealthcareClean N MEAN STD MIN MAX;
    VAR Age TSH_Level T3_Level T4_Level Nodule_Size;
RUN;

PROC FREQ DATA=HealthcareClean;
    TABLES Gender Family_History Radiation_Exposure Iodine_Deficiency 
           Smoking Obesity Diabetes Thyroid_Cancer_Risk Diagnosis / NOCUM;
RUN;

/* Step 4: OLS Regression for Exploratory Analysis */
PROC REG DATA=HealthcareClean;
    MODEL Risk = Age Gender_bin Family_History_bin Radiation_bin 
                 Iodine_Def_bin Smoking_bin Obesity_bin Diabetes_bin 
                 TSH_Level T3_Level T4_Level Nodule_Size 
                 Obesity_bin*Smoking_bin 
                 Radiation_bin*Family_History_bin;
RUN;
QUIT;

/* Step 5: Logistic Regression with Stepwise Selection */
PROC LOGISTIC DATA=HealthcareClean DESCENDING;
    CLASS Gender_bin Family_History_bin Radiation_bin Iodine_Def_bin 
          Smoking_bin Obesity_bin Diabetes_bin / PARAM=REF;

    MODEL Risk = Age Gender_bin Family_History_bin Radiation_bin 
                 Iodine_Def_bin Smoking_bin Obesity_bin Diabetes_bin 
                 TSH_Level T3_Level T4_Level Nodule_Size 
                 Obesity_bin*Smoking_bin 
                 Radiation_bin*Family_History_bin
                 / SELECTION=STEPWISE SLENTRY=0.05 SLSTAY=0.05;

    OUTPUT OUT=logit_out P=Predicted_Prob;
RUN;

/* Step 6: Model Evaluation with ROC Curve */
PROC LOGISTIC DATA=HealthcareClean DESCENDING;
    MODEL Risk = Age Gender_bin Family_History_bin Radiation_bin 
                 Iodine_Def_bin Smoking_bin Obesity_bin Diabetes_bin 
                 TSH_Level T3_Level T4_Level Nodule_Size 
                 Obesity_bin*Smoking_bin 
                 Radiation_bin*Family_History_bin;
    ROC;
RUN;

/* Step 7: Visualize Predicted Probabilities */
PROC SGPLOT DATA=logit_out;
    SCATTER X=Predicted_Prob Y=Risk;
    REFLINE 0.5 / AXIS=X LINEATTRS=(COLOR=red PATTERN=shortdash);
    XAXIS LABEL="Predicted Probability of High Thyroid Cancer Risk";
    YAXIS LABEL="Actual Risk (1=High)";
RUN;

/* Step 8: Country with Highest Diagnosis */
PROC FREQ DATA=HealthcareClean;
    TABLES Country*Thyroid_Cancer_Risk / NOCUM;
    TITLE 'Country with Highest Diagnosis of Thyroid Cancer';
RUN;

/* Step 9: Age Group Classification */
DATA HealthcareClean;
    SET HealthcareClean;
    LENGTH Age_Group $10.;
    IF Age < 30 THEN Age_Group = 'Under 30';
    ELSE IF 30 <= Age < 40 THEN Age_Group = '30-39';
    ELSE IF 40 <= Age < 50 THEN Age_Group = '40-49';
    ELSE IF 50 <= Age < 60 THEN Age_Group = '50-59';
    ELSE IF Age >= 60 THEN Age_Group = '60+';
RUN;

/* Step 10: Frequency of Diagnosis by Age Group */
PROC FREQ DATA=HealthcareClean;
    TABLES Age_Group*Thyroid_Cancer_Risk / NOCUM;
    TITLE 'Thyroid Cancer Diagnosis by Age Group';
RUN;

/* Step 11: Diagnosis by Country and Age Group */
PROC FREQ DATA=HealthcareClean;
    TABLES Country*Age_Group*Thyroid_Cancer_Risk / NOCUM;
    TITLE 'Thyroid Cancer Diagnosis by Country and Age Group';
RUN;

/* Step 12: Risk by Gender and Country */
PROC FREQ DATA=HealthcareClean;
    TABLES Country*Gender*Thyroid_Cancer_Risk / NOCUM;
    TITLE 'Thyroid Cancer Risk by Gender and Country';
RUN;

/* Step 13: Risk by Gender and Ethnicity */
PROC FREQ DATA=HealthcareClean;
    TABLES Ethnicity*Gender*Thyroid_Cancer_Risk / NOCUM;
    TITLE 'Thyroid Cancer Risk by Gender and Ethnicity';
RUN;

/* Step 14: Chi-Square Test for Gender */
PROC FREQ DATA=HealthcareClean;
    TABLES Gender*Thyroid_Cancer_Risk / CHISQ;
    TITLE 'Thyroid Cancer Risk by Gender (Chi-Square Test)';
RUN;

/* Step 15: Risk by Gender and Country (Redundant but useful summary) */
PROC FREQ DATA=HealthcareClean;
    TABLES Gender*Country*Thyroid_Cancer_Risk / NOCUM;
    TITLE 'Thyroid Cancer Risk by Gender and Country';
RUN;

/* Step 16: Risk by Gender and Ethnicity */
PROC FREQ DATA=HealthcareClean;
    TABLES Gender*Ethnicity*Thyroid_Cancer_Risk / NOCUM;
    TITLE 'Thyroid Cancer Risk by Gender and Ethnicity';
RUN;

proc hpforest data=HealthcareClean;
    target Risk / level=nominal;
    input Age TSH_Level T3_Level T4_Level Nodule_Size / level=interval;
    input Gender_bin Family_History_bin Radiation_bin 
          Iodine_Def_bin Smoking_bin Obesity_bin Diabetes_bin / level=nominal;
    
run;
PROC SQL;
    SELECT Country, Age_Group, Gender, Ethnicity, COUNT(*) AS High_Risk_Count
    FROM HealthcareClean
    WHERE Thyroid_Cancer_Risk = 'High'
    GROUP BY Country, Age_Group, Gender, Ethnicity
    ORDER BY High_Risk_Count DESC;
run;


