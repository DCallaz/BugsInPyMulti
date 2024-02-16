import sys


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


if __name__ == "__main__":
    if (len(sys.argv) < 2):
        print("USAGE: python3 lcs <string 1> <string 2>")
        exit(0)
    text1 = sys.argv[1]
    text2 = sys.argv[2]
    len1 = len(text1)
    len2 = len(text2)
    if (len1 > 0 and len2 > 0):
        res = huntSzymanski_lcs(text1, text2, len1, len2)
        print(int((res*100)/min(len1, len2)))
    elif (len1 > 0 or len2 > 0):
        print(0)
    else:
        print(100)
