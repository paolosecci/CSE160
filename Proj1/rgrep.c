//Paolo Secci
//CSE31
//Project 1

#include <stdio.h>
#define MAXSIZE 4096

int matches_leading(char *partial_line, char *pattern)
{
    //base cases
    if(!*pattern) {return 1;}
    if(!*partial_line || *partial_line == '\n') {return 0;}
    
    //next and prev pointers
    char *prev = pattern-1;
    char *next = pattern+1;
    
    
        //wildcard "\\"
        if(*pattern == '\\')
        {
            if (next != partial_line)
            {
                char* nextnext = next+1;
                if(*nextnext == '?')
                {
                    return matches_leading(partial_line, pattern+3);
                }
                else
                {
                    return 0;
                }
            }
            return matches_leading(partial_line+1, pattern+2);
        }
        //wildcard "."
        else if(*pattern == '.')
        {
            return matches_leading(partial_line+1, pattern+1);
        }
        //wildcard "+"
        else if(*pattern == '+')
        {
            if(*prev == '.')
            {
                if(*partial_line == *(partial_line-1))
                {
                    while(*partial_line == *(partial_line-1))
                    {
                        return matches_leading(partial_line+1, pattern);
                    }
                }
                else
                {
                    return matches_leading(partial_line, pattern+1);
                }
            }
            else if(*partial_line == *prev)
            {
                while(*partial_line == *prev)
                {
                    return matches_leading(partial_line+1, pattern);
                }
            }
            else
            {
                return matches_leading(partial_line, pattern+1);
            }
        }
        //wildcard "?"
        else if(*next == '?')
        {
            if(*partial_line == *pattern)
            {
                return matches_leading(partial_line+1, pattern+2);
            }
            else
            {
                return matches_leading(partial_line, pattern+2);
            }
        }
        else if(*pattern == '?')
        {
            return matches_leading(partial_line, pattern+1);
        }
        //no wildcards
        else if(*partial_line == *pattern)
        {
            return matches_leading(partial_line+1, pattern+1);
        }
        return 0;
}

int rgrep_matches(char *line, char *pattern)
{
    while(*line)
    {
        if(matches_leading(line, pattern) == 1)
        {
            return 1;
        }
        line++;
    }
    return 0;
}



//no touch
int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <PATTERN>\n", argv[0]);
        return 2;
    }
    
    /* we're not going to worry about long lines */
    char buf[MAXSIZE];
    
    while (!feof(stdin) && !ferror(stdin)) {
        if (!fgets(buf, sizeof(buf), stdin)) {
            break;
        }
        if (rgrep_matches(buf, argv[1])) {
            fputs(buf, stdout);
            fflush(stdout);
        }
    }
    
    if (ferror(stdin)) {
        perror(argv[0]);
        return 1;
    }
    
    return 0;
}
