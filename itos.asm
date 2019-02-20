.data  
file: .asciiz "input.txt"
buffer: .space 256

zero: .asciiz "zero"
one: .asciiz "one"
two: .asciiz "two"
three: .asciiz "three"
four: .asciiz "four"
five: .asciiz "five"
six: .asciiz "six"
seven: .asciiz "seven"
eight: .asciiz "eight"
nine: .asciiz "nine"

zero_chr: .asciiz "0"
nine_chr: .asciiz "9"
space_chr: .asciiz " "
dot_chr: .asciiz "."
	
.text
main:
	# input dosyasi uygun parametreler ile acilir.
	addi   $v0,$zero,13
	la   $a0, file
	addu   $a1,$zero,$zero
	addu  $a2,$zero,$zero
	syscall
	addu $s7,$v0,$zero # dosya tanimlayicisi registera alinir
	
	#datadaki isimde bir text dosyasi yoksa program bitirilir.
	slt $t0,$v0,$zero
	bne $t0,$zero,Exit
	
	addi $s5,$zero,1
	
	Loop:
		beq $t9,$zero,up
			add $s5,$t9,$zero
			add $t9,$zero,$zero
		up:
		
		jal read # dosyadan 1 byte okunup buffer a yazilir.

		beq  $v0,$zero,Exit  # eger okunan bir deger olmadiysa program bitirilir.
		# Buffer adresi a0 'a bufferdaki deger ise a3 e alinir.
		la $a0,buffer
		lb $a3,buffer
		# a3 deki degerin sayi olup olmadigina bakilir. Eger sayi degil ise ekrana bastirilir.	
		
		lb $t1,zero_chr
		lb $t2,nine_chr
	
		slt $t0, $t2,$a3
		bne $t0,$zero,prew_print#print
		slt $t0,$a3,$t1
		bne $t0,$zero,prew_print#print
	
		# Eger okunan ilk deger bir sayi ise bir deger daha okunur. Okunan bir deger olmadiysa
		# ilk okunan sayi icin islemler yapilir.
		jal read
	
		lb $a2,buffer
		
		addu $s3,$zero,$v0
		
		beq  $v0,$zero,next
		# okunan ikinci degerin nokta olup olmadigina bakilir. Eger nokta ise
		# float sayi olup olmadigina bakmak icin uygun yere gidilir.
		lb $t3,dot_chr
		beq $a2,$t3,second_dot
		# Ýkinci degerin sayi olup olmadigina bakilir. Eger ikinci degerde sayi ise print2 cagirilir.
		slt $t0, $t2,$a2
		bne $t0,$zero,next
	
		slt $t0,$a2,$t1
		bne $t0,$zero,next
		add $s5,$zero,$zero
	print2_l:	
		jal print2
		j Loop
	
	next:
		# Eger ikinci deger sayi degil ise sayiyi duzenlemek icin uygun fonksiyonlar cagirilir ve sornasinda sayi ekrana basilir.
		jal number_to_text
		jal upper_case
		j print
	Exit:
		# Dosya sonuna gelindigi zaman dosya kapatilir ve program sonlandirilir.
		addi   $v0,$zero,16 
		addu $a0,$s7,$zero
		syscall
		
		addi  $v0,$zero,10
    		syscall	
	print:
		# Okunan karakter ekrana basilir. Eger okunan ilk deger sayi ikincisi
		# degil ise donusturulmus sayi ile ikinci karakter ekrana basilir.
		addi $v0,$zero,4
		syscall
		beq $s3,$zero,p2#Loop # ikinci kez okuma yapilmis mi onu gosterir.
		
		la $a0,buffer
		sb $a2,($a0)
		addu $s3,$zero,$zero
		j print
		p2:
			beq $t7,$zero,Loop
			la $a0,buffer
			sb $t7,($a0)
			addu $t7,$zero,$zero
			j print
	prew_print:
		lb $t3,dot_chr
		lb $t5,space_chr
		bne $a3,$t3,up2
			addi $s5,$zero,1
			j print
		up2:
		beq $a3,$t5,up3
			add $s5,$zero,$zero
		up3:
		j print
		
# Sayi sonrasinda girilen noktanin cumle sonu mu yoksa float sayi mi oldugu anlasilir. 
second_dot:
	add $t5,$a3,$zero
	add $t6,$a2,$zero
	# noktadan sonrasi icin bir deger daha okunur. Okunan deger sayi ise 
	# en yakin bosluga kadar float sayiyi yazmasi icin print2 ye gidilir.
	# ilk deger ekrana yazilirak okunan deger yer degistirilir. Boylece deger kaybedilmemis olur.
	jal read
	add $a3,$t5,$zero
	add $a2,$t6,$zero
	
	lb $t7,buffer
	
	slt $t0, $t2,$t7
	bne $t0,$zero,not_number
	
	slt $t0,$t7,$t1
	bne $t0,$zero,not_number
	
	la $a0,buffer
	sb $a3,($a0)
	addi $v0,$zero,4
	syscall
	add $a3,$a2,$zero
	add $a2,$t7,$zero
	add $t7,$zero,$zero

	j print2_l
	not_number:	
		#okunan deger sayi degil ise ilk sayinin donusumu icin uygun yere gecilir.
		addi $t9,$zero,1
		j next
print2:
	# okunan iki deger de sayi ise ondalikli veya float sayi oldugu anlasilir.
	# sayi bitene kadar ekrana yazilir.
	lb $s4,space_chr
	la $a0,buffer
	sb $a3,($a0)
	addi $v0,$zero,4
	syscall
	sb $a2,($a0)
	addi $v0,$zero,4
	syscall
	addu $s3,$zero,$zero
	begin:
		# read cagirilirdin return adress karismamasi icin yedeklenir.
		addu $s2,$ra,$zero
		jal read 
	      	addu $ra,$s2,$zero
		beq  $v0,$zero,Exit
		lb $a3,buffer
		la $a0,buffer
		addi $v0,$zero,4
		syscall
		beq  $a3,$s4,end
		j begin
	end:
		jr $ra
# Sayi olarak verilen rakam text formatina cevrilir.
number_to_text:
	lb $s0,zero_chr
	la $s1,zero
	p_Loop:
	# 0 dan baslanilarak sayi bulanana kadar datadan veri okunur.
	#okunan datada ilerlenecek boyut icin find_size cagirilir.
		beq $a3,$s0,p_Exit
		addi $s0,$s0,1
		addu $s2,$ra,$zero
		jal find_size
		addu $ra,$s2,$zero
		j p_Loop	
	p_Exit:
	# sayi bulundugu zaman adres a0 a atilir ve yazdirilir.
		addu $a0,$s1,$zero
		jr $ra
find_size:
	# Datadan alinan texte null karakter bulunana kadar ilerlenir.
	# Null bulunduktan sonra bir adim daha gidilerek diger textin ilk harfine gelinir.
	size_loop:
		lb $s6,0($s1)
		beq $zero,$s6,size_Exit
		addi $s1,$s1,1
		j size_loop
	size_Exit:
		addi $s1,$s1,1
		jr $ra
read:
	# uygun parametreler ile dosyadan bir byte oknuur.
	addi   $v0,$zero,14
	addu $a0,$s7,$zero  
	la   $a1, buffer
	addi   $a2,$zero,1
	syscall 
	jr $ra
	# s5 registeri 1 ise yani buyuk yazilmasi gerekiyor ise a0 daki deger 32 azaltilarak tekrar a0 a atilir.
	# Boylece harf buyutulmus olur. 
upper_case:
	beq $s5,$zero,upper_end
	add $s5,$zero,$zero
	lb $t5,($a0)
	addi $t5,$t5,-32
	sb $t5, ($a0)
	upper_end:
		jr $ra
