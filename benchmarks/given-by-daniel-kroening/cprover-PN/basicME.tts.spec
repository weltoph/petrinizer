vars
s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 l0 l1 l2 l3 l4 l5 

rules
l0>=1, s0>=1 -> 
	l0'=l0-1,
	l1'=l1+1;

l0>=1, s0>=1 -> 
	s0'=s0-1,
	s1'=s1+1,
	l0'=l0-1,
	l1'=l1+1;

l0>=1, s1>=1 -> 
	s1'=s1-1,
	s2'=s2+1,
	l0'=l0-1,
	l2'=l2+1;

l0>=1, s2>=1 -> 
	s2'=s2-1,
	s3'=s3+1,
	l0'=l0-1,
	l3'=l3+1;

l1>=1, s3>=1 -> 
	s3'=s3-1,
	s4'=s4+1,
	l1'=l1-1,
	l4'=l4+1;

l1>=1, s3>=1 -> 
	s3'=s3-1,
	s7'=s7+1,
	l1'=l1-1,
	l5'=l5+1;

l4>=1, s3>=1 -> 
	s3'=s3-1,
	s10'=s10+1,
	l4'=l4-1,
	l1'=l1+1;

l5>=1, s3>=1 -> 
	s3'=s3-1,
	s11'=s11+1,
	l5'=l5-1,
	l1'=l1+1;

l2>=1, s4>=1 -> 
	s4'=s4-1,
	s5'=s5+1,
	l2'=l2-1,
	l0'=l0+1;

l3>=1, s5>=1 -> 
	s5'=s5-1,
	s6'=s6+1,
	l3'=l3-1,
	l0'=l0+1;

l0>=1, s6>=1 -> 
	s6'=s6-1,
	s3'=s3+1,
	l0'=l0-1,
	l2'=l2+1;

l2>=1, s7>=1 -> 
	s7'=s7-1,
	s8'=s8+1,
	l2'=l2-1,
	l0'=l0+1;

l3>=1, s8>=1 -> 
	s8'=s8-1,
	s9'=s9+1,
	l3'=l3-1,
	l0'=l0+1;

l0>=1, s9>=1 -> 
	s9'=s9-1,
	s3'=s3+1,
	l0'=l0-1,
	l3'=l3+1;

l0>=1, s10>=1 -> 
	s10'=s10-1,
	s3'=s3+1,
	l0'=l0-1,
	l3'=l3+1;

l0>=1, s11>=1 -> 
	s11'=s11-1,
	s3'=s3+1,
	l0'=l0-1,
	l2'=l2+1;


init
s1=0, s2=0, s3=0, s4=0, s5=0, s6=0, s7=0, s8=0, s9=0, s10=0, s11=0, l1=0, l2=0, l3=0, l4=0, l5=0, 
l0>=1, s0=1

target
s3>=1,l1>=1,l3>=1,l4>=2