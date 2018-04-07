//Paolo Secci
//CSE 31
//rgrep == restricted grep

#include <stdio.h>
#define MAXSIZE 4096

/**
 * You can use this recommended helper function
 * Returns true if partial_line matches pattern, starting from
 * the first char of partial_line.
 */
int rgrep_matches(char *partial_line, char *pattern)
{

}


/**
 * You may assume that all strings are properly null terminated
 * and will not overrun the buffer set by MAXSIZE
 *
 * Implementation of the rgrep matcher function
 */
int rgrep_matches(char *line, char *pattern)
{
    /
    if(*pattern)
    {
        //wildcard \'s
        if(pattern[0] == "\\")
        {
            if (line[0] == pattern[1])  //pattern[1] will have any of the following: \?+.
            {
                return rgrep_matches(*line + 1, *pattern + 2);
            }
            else
            {
                return rgrep_matches(*line + 1, *pattern);
            }
        }
        
        //wildcard ?'s
        if(pattern[1] == "?")
        {
            if(pattern[0] == line[0])
            {
                return rgrep_matches(*line + 1, *pattern + 2);
            }
            else
            {
                return rgrep_matches(*line, *pattern + 2);
            }
        }
        
        //wildcard +'s
        else if(pattern[1] == "+")
        {
            if(pattern[0] != line[0])
            {
                return rgrep_matches(*line + 1, *pattern);;
            }
            else if(pattern[0] == line[1])
            {
                return rgrep_matches(*line + 1, *pattern);
            }
            else if(pattern[0] == line[0])
            {
                return rgrep_matches(*line + 1, *pattern + 2);
            }
        }
        
        //wildcard .'s
        else if(pattern[0] == ".")
        {
            return rgrep_matches(*line + 1, *pattern + 1);
        }
        
        //no wildcards
        else if (pattern[0] == line[0])
        {
            return rgrep_matches(*line + 1, *pattern + 1);
        }
        
        return 0;
    }
    else
    {
        return 1;
    }
}


int main(int argc, char **argv)
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <PATTERN>\n", argv[0]);
        return 2;
    }
    
    /* we're not going to worry about long lines */
    char buf[MAXSIZE];
    
    while (!feof(stdin) && !ferror(stdin))
    {
        if (!fgets(buf, sizeof(buf), stdin))
        {
            break;
        }
        if (rgrep_matches(buf, argv[1]))
        {
            fputs(buf, stdout);
            fflush(stdout);
        }
    }
    
    if (ferror(stdin))
    {
        perror(argv[0]);
        return 1;
    }
    
    return 0;
}
