
# coding: utf-8

# In[1]:

import pandas as pd


# In[2]:

db = pd.read_csv("results.csv")


# In[3]:

dummies = pd.get_dummies(db,columns=["status"])
dummies_smaller = dummies[["position","status_Email Opened","status_Email Sent","status_Success"]]
dummies_smaller.columns = ["position","Email_Opened","Email_Sent","Success"]


# In[8]:

dummies_smaller.groupby(("position")).sum().reset_index().to_csv("smaller_output.csv",",",index= None)


# In[36]:

#dummies.to_csv("Output.csv",",",index= None)
#dummies_smaller.to_csv("smaller_output.csv",",",index= None)


import subprocess

subprocess.call(['chmod', '0777', "smaller_output.csv"])
