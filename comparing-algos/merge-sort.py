count = 0
def compareItems(a, b, comps):
    print("COMPARING")
    global count
    count += 1 # increment
    comps.append(a <= b)
    return a <= b

def mergeSort(arr, comps, index):
    width = 1   
    n = len(arr)                                          
    while (width < n):
        l = 0
        while (l < n): 
            r = min(l + (width * 2 - 1), n - 1)         
            m = min(l + width - 1, n - 1)
            merge(arr, l, m, r, comps, index)
            index += 1
            l += width * 2

        width *= 2
    return arr

def merge(arr, l, m, r, comps, index):
    print(index)
    print(comps)
    n1 = m - l + 1
    n2 = r - m 
    L = [0] * n1 
    R = [0] * n2 
    for i in range(0, n1): 
        L[i] = arr[l + i] 
    for i in range(0, n2): 
        R[i] = arr[m + i + 1]
 
    i, j, k = 0, 0, l
    while i < n1 and j < n2:
        # if L[i] <= R[j]:
        if index < len(comps) and comps[index] or compareItems(L[i], R[j], comps):
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

# arr = [5, 2, 3, 1, 4, 7, 6]
arr = [45, 87, 23, 10, 56, 72, 35, 91, 18, 63, 29, 5, 82, 47]
comparisons = []
mergeSort(arr, comparisons, 0)
print(arr)
print(comparisons)
