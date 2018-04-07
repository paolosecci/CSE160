#include <stdio.h>
#define MAXSIZE 4096

/**
 * You can use this recommended helper function 
 * Returns true if partial_line matches pattern, starting from
 * the first char of partial_line.
 */
 // Implement if desire

int backup_matches_leading(char *partial_line, char *pattern);
int matches_leading(char *partial_line, char *pattern) {
   
    if (!*pattern){
        return 1;
    }

    if (!*partial_line || *partial_line == '\n'){
        return 0;
    }
   

   char check = *(pattern + 1);

   if (*pattern == '\\'){
   		return backup_matches_leading(partial_line, pattern+1);
   	}

	if(*pattern == '.'){
   		if (check == '+'){
    			return (matches_leading(partial_line+1, pattern) || matches_leading(partial_line+1, pattern+2));
    	}
    		return matches_leading(partial_line + 1, pattern + 1);
 	}
	if(check == '?')
	{
    		if (*partial_line!=*pattern)
		{
           		return matches_leading(partial_line, pattern + 2);
           	}
	        return matches_leading(partial_line, pattern+2) || matches_leading(partial_line+1, pattern+2);
	}
	else if(check == '+')
	{
    		if (*partial_line!=*pattern) {
           		return 0;
           	}
	        return matches_leading(partial_line, pattern+2) || matches_leading(partial_line+1, pattern+2);
	}
	else
	{
		if (*partial_line == *pattern)
		{
	 		return matches_leading(partial_line + 1, pattern + 1);
		}
		else 
			return 0;
 	}    
}   



int backup_matches_leading(char *partial_line, char *pattern) {

   char check = *(pattern + 1);
	if (check == '?')
	{
		if (*partial_line!=*pattern)
		{
           		return matches_leading(partial_line, pattern + 2);
           	}
	        return matches_leading(partial_line, pattern+2) || matches_leading(partial_line+1, pattern+2);
	}
	else if(check == '+')
	{
		if (*partial_line != *pattern)
		{
	    		return 0;
	    	}
	    	return matches_leading(partial_line+1, pattern) || matches_leading(partial_line+1, pattern+2);
	}
	else{
		if(*partial_line == *pattern)
		{
			return matches_leading(partial_line+1, pattern+1);
		}
		else
			return 0;
	}
}

/**
 * You may assume that all strings are properly null terminated 
 * and will not overrun the buffer set by MAXSIZE 
 *
 * Implementation of the rgrep matcher function
 */
int rgrep_matches(char *line, char *pattern) {

    //
    // Implement me
    //
	while(*line){		//make sure that this is not a null character
		if(matches_leading(line, pattern) == 1){	//if function returns true, return true back to main
			return 1;
	}
	line++;			//increment to the next character
	}
	return 0;
}

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
