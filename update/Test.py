#!/usr/bin/env python


from download import download, importData
import os, os.path

import os
import re
import subprocess

def Test():
    files = {}
    cwd = os.getcwd()
    files['../data/University of Southampton/Developing Your Research Project/3 - 2015-06-22 - 2015-06-22/peer-review-reviews.csv'] = 3;
    importData(files,"University of Southampton")


def printCsv():
    print "Chaning the csv hex to unix style"
    output = subprocess.call(['../data/removeCarrigeReturn.sh', '../data'])
    filesDictionary = {}
    p = re.compile('([0-9]+) - [0-9]{4}-[0-9]{2}-[0-9]{2}')
    for root, dirs, files in os.walk('../data/'):
        for f in files:
            fullpath = os.path.join(root, f)
            if os.path.splitext(fullpath)[1] == '.csv':
                if "saud" not in fullpath:
                    matchObj = re.search(r'([0-9]+) - [0-9]+-[0-9]+-[0-9]+|Courses Data',fullpath)
                    if matchObj:
                        filesDictionary[fullpath] = matchObj.group(1)



    for fileDir, courseRuns in filesDictionary.items():
        print(fileDir)
        print(courseRuns)
    print("Loading Csvs into Database")
    importData(filesDictionary,"University of Southampton")

def processCourses():
    filesDictionary = {}
    filesDictionary["../data/University of Southampton/Courses Data/Data/Courses-Data.csv"] = 1
    print("Inserying courses data csv")
    importData(filesDictionary,"University of Southampton")
    print("Finished loading!")

def removeCarrige():
    print("Perfrom a shel script")
    output = subprocess.call(['../../TestCoding/removeCarrigeReturn.sh', '../../TestCoding/'])
    print("Done!")



printCsv()
#processCourses()