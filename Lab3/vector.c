//Paolo Secci

#include <stdlib.h>
#include <stdio.h>
#include "vector.h"

// Define struct
struct _vector_t
{
	size_t size;
	int *data;
};

//create new vector
vector_t *vector_new() {
	vector_t *retval;  

	//allocate struct mem
	retval = (vector_t *)malloc(1 * sizeof(vector_t));

	//check for memory
	if(retval == NULL)
		return NULL;
	 
	//initialize
	retval->size = 1;
	retval->data = (int *)malloc(retval->size * sizeof(int));

	//check for memory
	if(retval->data == NULL) {
		free(retval);
		return NULL;
	}
	retval->data[0] = 0;
    
	return retval;
}

//free space in memory
void vector_delete(vector_t *v)
{
	//free vector
	free(v->data);
    free(v);
}

//return vector value
int vector_get(vector_t *v, size_t loc) {

	//check if null
	if(v == NULL)
    {
		fprintf(stderr, "vector_get: passed a NULL vector.  Returning 0.\n");
		return 0;
	}

	//check requested location
	if(loc < v->size)
    {
		return v->data[loc];
	}
    else
    {
		return 0;
	}
}

//set vector value
void vector_set(vector_t *v, size_t loc, int value)
{
	//check v
	if(v==NULL)
	{
		v=(vector_t *)malloc(1*sizeof(vector_t *));
		v->size=loc+1;
		v->data=(int *)malloc((loc+1)*(sizeof(int *)));
		v->data[loc]=value;
	}
	else if(v->size>loc)
	{
		v->data[loc]=value;
	}
    else
	{
		//allocate memory for vector
		vector_t *backup = (vector_t *)malloc(1*sizeof(vector_t *));
		backup->size=v->size;
		backup->data=(int *)malloc((backup->size)*(sizeof(int *)));
		//insert data
		for(int i=0;i<backup->size;i++)
			backup->data[i]=v->data[i];
		//clear memory from v
		vector_delete(v);
		//re-allocate memory to v
		v=(vector_t *)malloc(1*sizeof(vector_t *));
		v->size=loc+1;
		v->data=(int *)malloc((loc+1)*(sizeof(int *)));
		//reset values to v
		for(int j=0;j<backup->size;j++)
			v->data[j]=backup->data[j];
		//insert new value
		v->data[loc]=value;
		//delete backup
		vector_delete(backup);
	}
}
