import random
import pandas as pd

# return a dict{array size, array} of random integers 1 to 1000
def generateTestCases():
    testCases = {}

    for n in range(2, 251):
        testCases[n] = [random.randint(1, 1000) for _ in range(n)]
    return testCases

# run the test cases, returning a dict{array size, number of comparisons}
def runTestCases(testCases, sortFunction):
    global count
    results = {}

    for n, testCaseList in testCases.items():
        count = 0
        sortFunction(testCaseList)
        results[n] = count # record number of comparisons
    return results

# custom compare function that increments the number of comparisons
def compareItems(a, b):
    global count
    count += 1 # increment
    return a < b

# implementation of the insertion sort algorithm
def insertionSort(arr):
    if len(arr) <= 1:
        return
 
    for i in range(1, len(arr)):
        key = arr[i]
        j = i - 1
        # here, the custom compare function is used instead of standard "<"
        while j >= 0 and compareItems(key, arr[j]):
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key

# implementation of the merge sort algorithm
def mergeSort(arr, l, r):
    if l < r:
        m = l + (r - l) // 2

        mergeSort(arr, l, m)
        mergeSort(arr, m + 1, r)
        merge(arr, l, m, r)

def merge(arr, l, m, r):
    n1 = m - l + 1
    n2 = r - m
 
    L = [0] * (n1)
    R = [0] * (n2)
 
    for i in range(0, n1):
        L[i] = arr[l + i]
 
    for j in range(0, n2):
        R[j] = arr[m + 1 + j]
 
    i = 0
    j = 0
    k = l
 
    while i < n1 and j < n2:
        if compareItems(L[i], R[j]):
            arr[k] = L[i]
            i += 1
        else:
            arr[k] = R[j]
            j += 1
        k += 1
 
    while i < n1:
        arr[k] = L[i]
        i += 1
        k += 1
 
    while j < n2:
        arr[k] = R[j]
        j += 1
        k += 1

def startMerge(arr):
    mergeSort(arr, 0, len(arr) - 1)

# the count of comparisons that functions may increment
# or reset, as if passed by reference as a parameter
count = 0

# generate and run each set of 1 to 250 large test cases 100 times
# return the stored results
def runAllTestCases():
    resultsList = []

    for i in range(100):
        testCases = generateTestCases()
        # results = runTestCases(testCases, insertionSort) # insertion sort
        results = runTestCases(testCases, startMerge) # merge sort
        resultsList.append(results)
    return resultsList

# compute averages
allResults = runAllTestCases()
sumCounts = {}
for result in allResults:
    for n, c in result.items():
        if n in sumCounts.keys():
            sumCounts[n] = sumCounts[n] + c
        else:
            sumCounts[n] = 0

# export csv of results
df = pd.DataFrame({"N": [i for i in range(2, 251)], "Comparisons": [sumCounts[i] / 100 for i in range(2, 251)]})
print(df)
df.to_csv("results.csv", index=False)
