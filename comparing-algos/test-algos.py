import random
import pandas as pd
import bisect

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

# <merge sort definitions>
def mergeSort(arr, l, r):
    if l < r:
        m = l + (r - l) // 2

        mergeSort(arr, l, m)
        mergeSort(arr, m + 1, r)
        merge(arr, l, m, r)

def merge(arr, l, m, r):
    n1 = m - l + 1
    n2 = r - m
 
    L = arr[l : m + 1]
    R = arr[m + 1 : r + 1]
 
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

# </merge sort definitions>
    
# <merge-insertion sort definitions>
class Pair:
    def __init__(self, small, large):
        self.small = small
        self.large = large

    def __lt__(self, other):
        # show ui comparison in product
        return self.large < other.large

    def __str__(self):
        return f"({self.small}, {self.large})"
    
def genJacobsthal(n):
    return (2 ** n - (-1) ** n) // 3

# return location of insertion
def binarySearch(arr, low, high, x):

    if high >= low:
        mid = (high + low) // 2
 
        if compareItems(x, arr[mid]):
            return binarySearch(arr, low, mid - 1, x)
 
        else:
            return binarySearch(arr, mid + 1, high, x)
 
    else:
        return low

def mergeInsertionSort(arr):
    # sort pairs in-place
    for i in range(0, len(arr) - 1, 2):
        if compareItems(arr[i + 1], arr[i]): # swap if necessary
            arr[i], arr[i + 1] = arr[i + 1], arr[i]

    # create Pair objects
    pairs = []
    for i in range(0, len(arr) - 1, 2):
        pairs.append(Pair(arr[i], arr[i + 1]))

    # sort pairs in-place by large value
    mergeSort(pairs, 0, len(pairs) - 1)

    # init main and pend chains
    main = [_.large for _ in pairs]
    pend = [_.small for _ in pairs]
    if len(arr) % 2 != 0:
        pend.append(arr[-1])
    # print("main", main)
    # print("pend", pend)

    # insert pend elements into main chain
    lastJ = 0
    added = 0
    while added < len(pend):
        # start next at next jacobsthal, not exceeding length of pend array
        nextJ = min(genJacobsthal(added + 2), len(pend))
        for i in range(0, nextJ - lastJ):
            pendIndex = nextJ - i - 1
            insertIndex = binarySearch(main, 0, added + pendIndex - 1, pend[pendIndex])
            main.insert(insertIndex, pend[pendIndex])
            added += 1
        lastJ = nextJ

    # print("\ndone", main)
# </merge-insertion sort definitions>


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
        # results = runTestCases(testCases, startMerge) # merge sort
        results = runTestCases(testCases, mergeInsertionSort) # merge-insertion sort
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
