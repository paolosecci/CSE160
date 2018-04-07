int proc(){
	return proc();
}

int main(){
	int a=1, b=2;
	proc();
	swap (&a, &b);
}