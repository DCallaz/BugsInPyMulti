import sys
import math
import copy
from itertools import permutations


def huntSzymanski_lcs(stringA, stringB, m, n):
    alphabet_size = 256
    # int i, j, k, LCS, high, low, mid;
    matchlist = [[0]*(n+2) for i in range(alphabet_size)]
    # int[] L;
    L = [0]*(n + 1)

    # make the matchlist
    for i in range(m):
        if (matchlist[ord(stringA[i])][0] == 0):
            matchlist[ord(stringA[i])][0] = 0
            k = 1
            for j in range(n-1, -1, -1):
                if (stringA[i] == stringB[j]):
                    matchlist[ord(stringA[i])][k] = j + 1
                    k += 1
                matchlist[ord(stringA[i])][k] = -1

    # finding the LCS
    LCS = 0
    for i in range(m):
        j = 0
        while (matchlist[ord(stringA[i])][j] != -1):
            # if the number bigger then the biggest number in the L, LCS + 1
            if (matchlist[ord(stringA[i])][j] > L[LCS]):
                LCS += 1
                L[LCS] = matchlist[ord(stringA[i])][j]
            # else, do the binary search to find the place to insert the number
            else:
                high = LCS
                low = 0
                k = 0
                while (True):
                    mid = low + (int)((high - low) / 2)
                    if (L[mid] == matchlist[ord(stringA[i])][j]):
                        k = 1
                        break
                    if (high - low <= 1):
                        mid = high
                        break
                    if (L[mid] > matchlist[ord(stringA[i])][j]):
                        high = mid
                    elif (L[mid] < matchlist[ord(stringA[i])][j]):
                        low = mid
                if (k == 0):
                    L[mid] = matchlist[ord(stringA[i])][j]
            j += 1
    return LCS


def greedy_perm(len2, len1, comps):
    """
    An alternative to the itertools.permutations function, which gives a single
    permutation by a greedy strategy.
    """
    comps = copy.deepcopy(comps)
    max_perm = [-1 for _ in range(len1)]
    max_sum = 0
    ms = sorted([(x, i2, i1) for i2, y in enumerate(comps) for i1, x in
          enumerate(y)], reverse=True)
    for _ in range(len1):
        # Get the max (with indices)
        m, i2, i1 = ms[0]
        # Add to the solution
        max_perm[i1] = i2
        max_sum += m
        # Remove row and column
        ms = [m for m in ms if m[1] != i2 and m[2] != i1]
    return max_sum, max_perm


if __name__ == "__main__":
    if (len(sys.argv) < 2):
        print("USAGE: python3 lcs <string 1> <string 2>")
        exit(0)
    texts1 = sys.argv[1].split("\n")
    texts2 = sys.argv[2].split("\n")
    # Make sure texts1 is always the shortest
    if (len(texts1) > len(texts2)):
        texts1, texts2 = texts2, texts1
    comps = [[0 for i1 in range(len(texts1))] for i2 in range(len(texts2))]
    max_lcs = 0
    for i1, text1 in enumerate(texts1):
        for i2, text2 in enumerate(texts2):
            len1 = len(text1)
            len2 = len(text2)
            if (len1 > 0 and len2 > 0):
                res = huntSzymanski_lcs(text1, text2, len1, len2)
                comps[i2][i1] = int((res*100)/min(len1, len2))
            elif (len1 > 0 or len2 > 0):
                comps[i2][i1] = 0
            else:
                comps[i2][i1] = 100
    # Determine if greedy strategy needed
    if (math.perm(len(texts2), len(texts1)) > 4e7):
        # Perform greedy strategy
        max_sum, max_perm = greedy_perm(len(texts2), len(texts1), comps)
    else:
        # Calculate the maximum sum by considering all permutations
        max_sum = 0
        max_perm = None
        for perm in permutations(range(len(texts2)), len(texts1)):
            cur_sum = sum([comps[i2][i1] for (i1, i2) in enumerate(perm)])
            if (cur_sum > max_sum):
                max_sum = cur_sum
                max_perm = perm
    # print(texts1, texts2, comps, max_perm, sep="\n")
    print(int(max_sum/len(texts1)))
