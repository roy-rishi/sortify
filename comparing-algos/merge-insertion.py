count = 0
def compareItems(a, b):
    global count
    count += 1 # increment
    return a < b

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

    print("\ndone", main)

# arr = [5, 2, 3, 1, 4, 7, 6]
arr = [45, 87, 23, 10, 56, 72, 35, 91, 18, 63, 29, 5, 82, 47]
mergeInsertionSort(arr)
