class lcs {
  private static int huntSzymanski_lcs(char[] stringA, char[] stringB, int m, int n) {
    final int alphabet_size = 256;
    int i, j, k, LCS, high, low, mid;
    int[][] matchlist = new int[alphabet_size][];
    int[] L;
    for (i = 0; i < alphabet_size; i++) {
      matchlist[i] = new int[n + 2];
    }
    L = new int[n + 1];

    // make the matchlist
    for (i = 0; i < m; i++) {
      if (matchlist[stringA[i]][0] == 0) {
        matchlist[stringA[i]][0] = 0;

        for (k = 1, j = n - 1; j >= 0; j--) {
          if (stringA[i] == stringB[j]) {
            matchlist[stringA[i]][k] = j + 1;
            k++;
          }
          matchlist[stringA[i]][k] = -1;
        }
      }
    }

    // finding the LCS
    for (LCS = 0, i = 0; i < m; i++) {
      for (j = 0; matchlist[stringA[i]][j] != -1; j++) {
        // if the number bigger then the biggest number in the L, LCS + 1
        if (matchlist[stringA[i]][j] > L[LCS]) {
          LCS++;
          L[LCS] = matchlist[stringA[i]][j];
        }
        // else, do the binary search to find the place to insert the number
        else {
          high = LCS;
          low = 0;
          k = 0;
          while (true) {
            mid = low + ((high - low) / 2);
            if (L[mid] == matchlist[stringA[i]][j]) {
              k = 1;
              break;
            }
            if (high - low <= 1) {
              mid = high;
              break;
            }
            if (L[mid] > matchlist[stringA[i]][j]) {
              high = mid;
            } else if (L[mid] < matchlist[stringA[i]][j]) {
              low = mid;
            }
          }
          if (k == 0) {
            L[mid] = matchlist[stringA[i]][j];
          }
        }
      }
    }
    return LCS;
  }

  public static void main(String[] args) {
    if (args.length < 2) {
      System.out.println("USAGE: java lcs <string 1> <string 2>");
    }
    String text1 = args[0];
    String text2 = args[1];
    int len1 = text1.length(), len2 = text2.length();
    if (len1 > 0 && len2 > 0) {
      int res = huntSzymanski_lcs(text1.toCharArray(), text2.toCharArray(), len1, len2);
      System.out.println((res)*100/(Math.min(len1, len2)));
    } else if (len1 > 0 || len2 > 0) {
      System.out.println(0);
    } else {
      System.out.println(100);
    }
  }
}
