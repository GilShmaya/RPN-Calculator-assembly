%macro _malloc 2                                                                           
  push ebx
  push ecx
  push edx                                                      ; manually phshad - result (pinter to new item) would be in eax
  push %1                                                       ; size_t nitems
  push %2                                                       ; size_t size
  call malloc                                                   ; malloc(size_t nitems, size_t size)
  add esp, 8                                                    ; “free" space allocated for function arguments in Stack
  pop edx
  pop ecx
  pop ebx
%endmacro

%macro print_one_arg 3
  pushad                                                        ; push all signficant registers onto stack (backup registers values)
  push %3                                                       ; thirth argument: arg to print
  push %2                                                       ; second argument: format string
  push %1                                                       ; first argument: file * stream
  call fprintf                                                  ; call c func printf(const char *format, int)
  add esp, 12                                                   ; “free" space allocated for function arguments in Stack
  popad
%endmacro

%macro error_handle 1
  print_one_arg dword [stderr], formatString, %1                ; print error if there is not enough operand in stack
  jmp getinput                                                  ; next input
%endmacro

%macro check_overflow 0
  mov ecx, dword[stack_size]
  cmp dword[curr_stack_size], ecx                               
  jl %%finish_check_overflow                                    ; there is no overflow -> continue
  error_handle overflow_error                                   ; ptint error in case of overflow
  %%finish_check_overflow:
%endmacro
                                                                ; macro -> return value (length of string) to %2, string at %1
%macro getLen 2                                                 
  mov %2, 0                                                     ; counter
  %%calculate_len:
  cmp byte[%1 + %2], 0                                          ; checks if the next character (character = byte) is zero (i.e. null string termination)
  je %%finish_getLen
  cmp byte[%1 + %2], 10                                         ; checks if \n
  je %%finish_getLen
  inc %2                                                        ; continue to next char
  jmp %%calculate_len
  %%finish_getLen:
%endmacro
                                                                ; gets the address of the first link (%1) and return the last index of the list (%2), ebx is in used
%macro getlastindexlist 2                                            
  push ebx
  mov %2, 0                                                     ; counter index
  mov ebx, %1 
  %%calculate_listlen:
  add ebx, 4                                                    ; skip the first 4 bytes of the digit in the list
  cmp dword[ebx], 0                                             ; checks if the address in the pointer part of the link is 0 (null ptr)
  je %%finishgetlastindexlist
  inc %2                                                        ; counter ++
  mov ebx, [ebx]                                                ; continue to next link                                                   
  jmp %%calculate_listlen
  %%finishgetlastindexlist:
  pop ebx
%endmacro
                                                                ; return a pointer to link at index. return value at eax. %1 pointer to first link, %ecx index
%macro get_link_at_index 2                                      
  push ecx                                                      ; backup
  mov eax, %1                                                   ; eax is the address to first link
  mov ecx, %2                                                   ; ecx is the idex
  %%get_link_loop:
  cmp ecx, 0
  jle %%finish_get_link_at_index
  add eax, 4                                                    ; skip the first 4 bytes of the digit in the list
  mov eax, [eax]                                                ; continue to next link 
  dec ecx
  jmp %%get_link_loop
  %%finish_get_link_at_index:
  pop ecx
%endmacro

%macro _free 1
  pushad                                                        ; backup
  push %1                                                       ; %1 = address to free
  call free
  add esp, 4
  popad
%endmacro 
                                                                ; free the link. edx is the address of the link.
%macro freelink 1
  pushad                                                        ; backup
  getlastindexlist %1 , ecx                                     ; gets the address of the first link (%1) and return the last index of the list (%2)
  %%free_from_the_end:
  cmp ecx, 0                                                    ; starts printing from the last link (the first digit)
  jl %%finishfreelink
  get_link_at_index %1, ecx                                     ; return a pointer to link at index. return value at eax
  dec ecx
  add eax, 4                                                    ; eax pointer to address part in link
  cmp dword[eax], 0                                             ; checks if this is the last link
  je %%free_from_the_end
  _free dword[eax]
  jmp %%free_from_the_end 
  %%finishfreelink:
  _free  %1                                                     ; free the first link
  popad
%endmacro
                                                                ; reverse input srting and add null terminated char at the end. %1 = last index in string
%macro reverseinput 1
  pushad
  mov ecx, 0                                                    ; ecx = first index in input
  mov ebx, %1                                                   ; ebx = last index in input
  %%remove_zero_from_end:
  cmp ebx, 0                                                    ; checks if input is only one digit (including 0)
  je %%add_nul_char                                             ; if ebx == 0 so this is only one digit
  cmp byte[input + ebx], '0'
  jne %%add_nul_char
  dec ebx
  jmp %%remove_zero_from_end                                    ; continue
  %%add_nul_char:
  mov byte[input + ebx + 1], 0
  %%reverse:
  cmp ecx, ebx                                                  ; we will done reversing when start >= end (ecx >= ebx)
  jge %%done_reverseinput
  mov al, byte[input + ecx]                                     ; el = temp
  mov ah, byte[input + ebx] 
  mov byte[input + ecx], ah                                     ; insert char from the end to the begining
  mov byte[input + ebx], al                                     ; insert char from the beginning to the end
  inc ecx                                                       ; start ++
  dec edx                                                       ; end --
  %%done_reverseinput:
  popad 
%endmacro

%macro checks_size_stack_valid 0
  cmp dword[stack_size], 2
  jl done
%endmacro

%macro handle_debug_mode 0                                      ;prints the first operand in stack
  pushad
  cmp dword[debug_mode], 0                                      ; checks if debug mode is on
  je %%done_handle_debug_mode
  sub dword[stack_pos], 4                                       ; stack_pos points to the last cell in stack
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack
  mov edx, [edx]                                                ; edx is the context of the last cell in stack (the address of the link)
  getlastindexlist edx , ecx                                    ; gets the address of the first link (%1) and return the last index of the list (%2)
  %%debug_print_digit_from_end:
  cmp ecx, 0                                                    ; starts printing from the last link (the first digit)
  jl %%done_debug_print_digit_from_end
  get_link_at_index edx, ecx                                    ; return a pointer to link at index. return value at eax
  print_one_arg  dword [stderr], formatInt , dword[eax]
  dec ecx
  jmp %%debug_print_digit_from_end                              ; next digit
  %%done_debug_print_digit_from_end:
  print_one_arg  dword [stderr], formatString , newline
  add dword[stack_pos], 4                                       ; stack_pos points to the last free cell in stack
  %%done_handle_debug_mode:
  popad
%endmacro


section .data                    	                              ; we define (global) initialized variables in .data section
  inputlen: dd 80              		                              ; inputlen is a local variable of size double-word, we use it to 
  curr_stack_size: dd 0                                         ; current number of operand in stack
  stack_size: dd 5                                              ; default stack size - 5
  action_counter: dd 0                                          ; count the number of operations
  op1_size: dd 0                                                ; operand size
  op2_size: dd 0                                                ; operand size
  debug_mode: dd 0

section .rodata                    	                            ; we define read only (global) initialized variables in .data section
  formatString:       db "%s", 0                                ; db = byte.  ; The printf format, "\n" + null byte. (all - 4 bytes)
  formatChar:         db "%c", 0                                ; db = byte.  ; The printf format, "\n" + null byte. (all - 4 bytes)
  formatInt:          db "%d", 0                                ; db = byte.  ; The printf format, "\n" + null byte. (all - 4 bytes)
  formatIntOCT:       db "%o", 10, 0

  calcStr:            db "calc: ", 0                              
  insufficient_error: db "Error: Insufficient Number of Arguments on Stack", 10, 0
  overflow_error:     db "Error: Operand Stack Overflow", 10, 0
  newline:            db "", 10, 0                              


section .bss
  head_of_stack: resb 4                                         ; pointer to head of stack
  stack_pos: resb 4                                             ; pointer to last operand in stack
  link_pos: resb 4                                              ; pointer to link 
  link_pos2: resb 4                                             ; pointer to link
  input: resb 80                                                ; pointer to input. Each input line is no more than 80 characters in length.  
  tmp: resb 4                                                ; pointer to input. Each input line is no more than 80 characters in length.  
  carry: resb 1                                                 ; carry of sum 
  num1: resb 4                                                  ; pointer to number1
  num2: resb 4                                                  ; pointer to number2
  len1: resb 4                                                  ; len of number1
  len2: resb 4                                                  ; len of number2

section .text
  align 16
  global main
  extern printf
  extern fprintf 
  extern fflush
  extern malloc 
  extern calloc 
  extern free 
  extern getchar 
  extern fgets 
  extern stdout
  extern stdin
  extern stderr


main:
  push ebp              		                                    ; save Base Pointer (bp) original value
  mov ebp, esp         		                                      ; use Base Pointer to access stack contents (main activation frame)
  pushfd                                                        ; backup EFLAGS
  
  ;first - checks if debug mode is needed and what is the stack size 
  mov esi, dword[ebp + 12]                                      ; **argv
  mov ecx, dword[ebp + 8]                                       ; gets argc
  mov ebx, ecx                                                  
  dec ebx                                                       ; ebx = index to last index of args
  check_args:
  cmp ecx, 1                                                    ; check if argc = 1 => no argument
  je allocate_stack                                             ; checks if args has debug mode and stack length
  
  mov edx, dword[esi + ebx * 4]                                 ; edx is the address of the arg
  cmp word[edx], '-d'                                           ; checks if the argument is -d
  jne change_size_stack
  debug_on:
  mov dword[debug_mode], 1                                      ; turn on debug mode
  dec ecx
  dec ebx                                                       ; skip to next arg
  jmp check_args
  
  change_size_stack:
  mov dword[stack_size], 0
  loop_size_stack:
  cmp byte[edx], 0                                              ; checks if null char
  je done_change_size_stack
  shl dword[stack_size], 3                                      ; saves 3 bits to the next digit
  movzx eax, byte[edx]                                          ; eax = next digit
  sub eax, 48                                                   ; changes from ascii to binary
  or dword[stack_size], eax                                     ; add the digit to the lsb of stack_size
  inc edx
  jmp loop_size_stack
  done_change_size_stack:
  checks_size_stack_valid                                       ; checks if the size stack is greater than 2
  dec ecx
  dec ebx                                                       ; skip to next arg
  jmp check_args  


  allocate_stack:
  mov al, byte[stack_size]                                      ; The stack size is at most 63 (0q77), which is less than 8 bits
  mov bl, 4                                                     ; each cell of the stack saves an address of a operand linked list. A pointer is int (4 bytes)
  mul bl                                                        ; al (size stack) * 4. result of mul is in ax
  _malloc 1, ax
  mov dword[head_of_stack], eax
  mov dword[stack_pos], eax                                     ; pointer to next avilable cell

  getinput:
  print_one_arg dword [stdout], formatString, calcStr           ; print "calc:"
  pushad                                                        ; push all signficant registers onto stack (backup registers values)
  push dword [stdin]                                            ; thirth args of fgets -> FILE *stream
  push dword[inputlen]                                          ; second args of fgets -> length
  push input                                                    ; first args of fgets -> *str
  call fgets                                                    ; char *fgets(char *str, int n, FILE *stream)
  add esp, 12                                                   ; “free" space allocated for function arguments in Stack
  popad

  check_input:
  isQuit:
  cmp byte[input], 'q'                                          
  je quit
  isPlus:
  cmp byte[input], '+'                                          
  je plus
  isPop_and_print:
  cmp byte[input], 'p'                                          
  je pop_and_print
  isDuplicate:
  cmp byte[input], 'd'                                          
  je duplicate
  isBitwiseAND:
  cmp byte[input], '&' 
  je bitwise_and
  isNumberOfBytes:
  cmp byte[input], 'n' 
  je number_of_bytes
  isNumber:                                                     ; since the input should be a valid character, if the input is non of the option above -> it is a number
  jmp push_number
  
  plus:                                                         ; pop two operands from operand stack, and push the result, their sum
  inc dword[action_counter]
  cmp dword[curr_stack_size], 2                                 ; checks if there are at least two operrands
  jge do_plus
  error_handle insufficient_error                               ; print error if there is not enough operand in stack
  do_plus:                                                      ; does num+num- todo
  mov byte[carry], 0                                            ; initialize carry
  sub dword[stack_pos], 4                                       ; to go to the last place in stack where there IS a number
  mov eax, dword [stack_pos]                                    ; eax= pointer to place in stack of number1 
  mov eax, [eax]                                                ; eax= points to what is in the stack-> pointer to link of first number
  mov dword [num1], eax                                         ; num1 points to link of first number
  mov ecx, dword[len1]
  getlastindexlist eax, ecx  
  mov dword[len1], ecx                                          ; len1 holds number of links in num1
  sub dword[stack_pos], 4                                       ; to go to next the last place in stack where there IS a number
  mov eax, dword [stack_pos]                                    ; eax= pointer to place in stack of number2
  mov eax, [eax]                                                ; eax= points to what is in the stack-> pointer to link of second number
  mov dword [num2], eax                                         ; num2 points to link of second number
  mov ecx, dword[len2]
  getlastindexlist eax, ecx                                     ; len2 holds number of links in num
  mov dword[len2], ecx
  _malloc 1,8                                                   ; allocate place in the address of the list for new number- first link. eax->address of new link
  mov esi, eax                                                  ; adress of new number-> pointer to link-> to put in the end of the opperation in stack = esi
  mov dword[link_pos], eax                                      ; link pos= address to firstlink
  mov edx, 0                                                    ; edx= counter of digits we did
  startOfsum:
  mov ebx,0                                                     ; curr_digit of num1- initialized to 0 if doesnt exist
  mov ecx,0                                                     ; curr_digit of num2- initialized to 0 if doesnt exist
  cmp dword[len1],0
  jl finish_num1                                                ; if less- finished with number1. check if also number 2 finished
  ; else- put the correct byte of num1:
  get_link_at_index dword[num1], edx                            ; get the link of the cuurent digit in num1 and put in eax
  mov ebx, dword[eax]                                           ; now bx has the digit of number 1 of this round
  cmp dword[len2], 0                                            ; check if digit of num2 exist
  jl _add  
  ; if not- start sum
  ; else- put the correct byte of num2:
  do_num2:
  get_link_at_index dword[num2], edx                            ; get the link of the cuurent digit in num2 and put in eax
  mov ecx,  dword[eax]                                          ; now cl has the digit of number2 of this round
  jmp _add
  finish_num1: 
  cmp dword[len2], 0
  jl finish_both
  jmp do_num2                                                   ; there is a digit in num2- get it
  _add:
  add ecx, ebx                                                  ; ecx is in ecx (2byte-word), bx in ebx(word) = because we might have carry
  add cl, byte [carry]                                          ; add the carry
  mov byte[carry], cl           
  and byte[carry], 1000b
  shr byte[carry], 3
  and ecx, 0111b
  mov eax, dword [link_pos]                                     ; edx points to link
  mov dword [eax], ecx                                          ; cl is the byte of the sum- without the carry
  add dword[link_pos], 4                                        ; to put the address to next place
  dec dword[len1]
  dec dword[len2]
  cmp dword[len1] ,0
  jge addLink
  cmp dword[len2] ,0
  jl finish_both
  addLink:
  _malloc 1,8                                                   ; allocate next link
  mov ecx, dword[link_pos]                                      ; ecx= address that link_pos equals- address of next link- where we want to put the address of next link
  mov [ecx], eax                                                ; [ecx]= where we want to put the address= address of next link
  mov dword[link_pos], eax                                      ; update link pos to be the address of new link
  inc edx                                                       ; next digit to do
  jmp startOfsum
  finish_both:
  cmp byte[carry], 0                                            ; check if need to add carry
  je insertnewnumber
  _malloc 1,8                                                   ; allocate next link
  mov ecx, dword[link_pos]                                      ; ecx= address that link_pos equals- address of next link- where we want to put the address of next link
  mov [ecx], eax                                                ; [ecx]= where we want to put the address= address of next link
  mov dword[link_pos], eax                                      ; update link pos to be the address of new link
  mov edx, dword [link_pos]                                     ; edx points to link
  movzx ecx, byte[carry]
  mov dword[edx], ecx                                           ; adds the carry
  add dword[link_pos], 4                                        ; to put the address to next place
  insertnewnumber:
  mov edx, [link_pos]                                           ; edx is the pointer to the address part in the link
  mov dword[edx], 0                                             ; null pointer (has value 0) - this is the last link  mov edx, dword[num1] 
  freelink dword[num1]
  dec dword[curr_stack_size]
  freelink dword[num2]
  dec dword[curr_stack_size]
  mov eax, dword [stack_pos]                                    ; put pointer to place in stack available to put new number
  mov [eax], esi                                                ; put the pointer to the link of new number in the place in stack
  inc dword[curr_stack_size]
  add dword[stack_pos], 4                                       ; stack_pos points to the last free cell in stack
  handle_debug_mode
  jmp getinput
 

  pop_and_print:                                                ; pop one operand from the operand stack, and print its value to stdout
  inc dword[action_counter]
  cmp dword[curr_stack_size], 0                                 ; checks if there are at least one operrands
  jg do_pop_and_print
  error_handle insufficient_error                               ; print error if there is not enough operand in stack
  do_pop_and_print:
  sub dword[stack_pos], 4                                       ; stack_pos points to the last cell in stack
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack
  mov edx, [edx]                                                ; edx is the context of the last cell in stack (the address of the link)
  getlastindexlist edx , ecx                                    ; gets the address of the first link (%1) and return the last index of the list (%2)
  print_digit_from_end:
  cmp ecx, 0                                                    ; starts printing from the last link (the first digit)
  jl done_pop_and_print
  get_link_at_index edx, ecx                                    ; return a pointer to link at index. return value at eax
  print_one_arg  dword [stdout], formatInt , dword[eax]
  dec ecx
  jmp print_digit_from_end                                      ; next digit
  done_pop_and_print:
  print_one_arg  dword [stdout], formatString , newline
  freelink edx                                                   ; free the link. edx is the address of the link.
  dec dword[curr_stack_size]
  jmp getinput


  duplicate:                                                    ; push a copy of the top of the operand stack onto the top of the operand stack
  inc dword[action_counter]
  check_overflow 
  cmp dword[curr_stack_size], 0                                 ; checks if there are at least one operrands
  jg do_duplicate
  error_handle insufficient_error                               
  do_duplicate:
  sub dword[stack_pos], 4                                       ; stack_pos points to the last cell in stack
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack
  mov edx, [edx]                                                ; edx is the context of the last cell in stack (the address of the link)
  getlastindexlist edx , ecx                                    ; gets the address of the first link (%1) and return the last index of the list (%2)
  mov ebx, 0                                                    ; counter in input array
  print_digits_to_input_array:
  cmp ecx, 0                                                    ; starts printing from the last link (the first digit)
  jl push_duplicates_number
  get_link_at_index edx, ecx                                    ; return a pointer to link at index. return value at eax
  movzx eax, byte[eax]
  mov byte[input + ebx], al                                     ; digit (0-7) takes 3 bits so one byte is enough
  add byte[input + ebx], 48                                     ; saves in ascii
  inc ebx                                                       
  dec ecx
  jmp print_digits_to_input_array                               ; copy next digit to input array
  push_duplicates_number:
  mov byte[input + ebx], 0                                      ; add null terminated char
  add dword[stack_pos], 4                                       ; stack_pos points to the last free cell in stack
  jmp push_number


  bitwise_and:
  inc dword[action_counter]
  cmp dword[curr_stack_size], 2                                 ; checks if there are at least two operrands
  jge do_bitwise_and
  error_handle insufficient_error                               
  do_bitwise_and:
  sub dword[stack_pos], 4                                       ; stack_pos points to the last cell in stack
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack X
  mov eax, dword[edx]
  mov dword[link_pos], eax                                      ; link_pos is the address of first link of first operand X
  sub edx, 4                                                    ; edx is the pointer to the second last cell in stack Y
  mov eax, dword[edx]
  mov dword[link_pos2], eax                                     ; link_pos2 is the address of first link of first operand Y
  getlastindexlist dword[link_pos], dword[op1_size]             ; op1_size1 will be the last index in the first operand X
  getlastindexlist dword[link_pos2], dword[op2_size]            ; op1_size2 will be the last index in the second operand Y
  mov ebx, 0                                                    ; counter in input array
  loop_bitwise_and:
  cmp ebx, dword[op1_size]                                      ; there is no more digit in first operand X so & result will be 0 for this index of digit
  jg done_bitwise_and
  cmp ebx, dword[op2_size]                                      ; there is no more digit in second operand Y so & result will be 0 for this index of digit
  jg done_bitwise_and
  get_link_at_index dword[link_pos], ebx                        ; return a pointer to link at index. return value at eax
  mov cl, byte[eax]                                             ; cl is the next byte in the first operand X
  get_link_at_index dword[link_pos2], ebx                                     
  mov ch, byte[eax]                                             ; cl is the next byte in the second operand Y
  and cl, ch                                                    ; cl is the byte after AND
  mov byte[input + ebx], cl                                     ; digit (0-7) takes 3 bits so one byte is enough
  add byte[input + ebx], 48                                     ; saves in ascii
  inc ebx
  jmp loop_bitwise_and                                          ; next byte
  done_bitwise_and:
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack
  freelink dword[edx]                                           ; free the first link
  sub dword[stack_pos], 4                                       ; stack_pos = the address of the second cell in stack
  mov edx, [stack_pos]                                          ; edx is the pointer to the second last cell in stack
  freelink dword[edx]
  sub dword[curr_stack_size], 2
  dec ebx                                                       ; ebx = last index in input
  reverseinput ebx
  jmp push_number 

  number_of_bytes:                                              ; number of bytes the number is taking. pop one operand from the operand stack, and push one result.
  inc dword[action_counter]
  cmp dword[curr_stack_size], 0                                 ; checks if there are at least one operrands
  jg do_number_of_bytes
  error_handle insufficient_error                               ; print error if there is not enough operand in stack
  do_number_of_bytes:
  sub dword[stack_pos], 4                                       ; stack_pos points to the last cell in stack
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack
  mov edx, [edx]                                                ; edx is the context of the last cell in stack (the address of the link)
  getlastindexlist edx , ecx                                    ; gets the address of the first link (%1) and return the last index of the list (%2)
  sum_of_bits:
  mov al, cl                                                    ; al = size - 1, (the size should take less than byte - Each input line is no more than 80 characters in length.
  mov ah, 3
  mul ah                                                         ; al * 3 = (size -1) *3 . result of mul is in ax = num of bytes without the msb
  movzx ebx, ax                                                 ; ebx = sum of bits
  get_link_at_index edx, ecx                                    ; result at eax
  mov ecx, dword[eax]                                           ; ecx = the first digit of the operand
  checks_if_3_bit:
  and ecx, 0100b                                                ; checks if the digit takes 3 bits
  jz checks_if_2_bit
  add ebx, 3
  jmp calculate_sum_of_byte
  checks_if_2_bit:
  and ecx, 0010b                                                ; checks if the digit takes 2 bits
  jz add_1_bit
  add ebx, 2
  jmp calculate_sum_of_byte
  add_1_bit:
  add ebx, 1
  calculate_sum_of_byte:
  mov ax, bx                                                    ; ax = bx = sum of bits
  mov bl, 8
  div bl                                                        ; sum of bits \ 8 = num of bytes - Remainder. Quotient = al, Remainder = ah
  cmp ah, 0
  je done_calculate_sum_of_byte
  inc al                                                        ; there is an reminder so there is one more byte
  done_calculate_sum_of_byte:
  movzx ebx, al                                                 ; ebx is the num of byte                               
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack
  mov edx, [edx]                                                ; edx is the context of the last cell in stack (the address of the link)
  freelink edx                                                  ; free the link. edx is the address of the link.
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack
  _malloc 1,8                                                   ; allocate first link
  mov [edx], eax                                                ; insert the address of the new link list to the cell in stack
  mov [link_pos], eax                                           ; link pos pointer to the new link
  insert_link_number_of_bytes:
  mov ecx, ebx                                                
  and ecx, 0111b                                                ; we will check only the last 3 bits. ecx = the last 3 bits
  mov edx, [link_pos]                                           ; edx is the pointer to the digit part in the link
  mov dword[edx], ecx                                           ; copy the digit in binary to link
  add dword[link_pos], 4                                        ; pointer to address of next link
  shr ebx, 3                                                    ; next 3 bits
  cmp ebx, 0                                                    ; as a result of the shr, we will finish when ebx = 0 (done writing all digits =  3 bits each)                                    
  je done_number_of_bytes
  _malloc 1, 8                                                  ; new link in arg link list
  mov edx, [link_pos]                                           ; edx is the pointer to the pointer part in the link
  mov [edx], eax                                                ; saves pointer to next link
  mov dword[link_pos], eax
  jmp insert_link_number_of_bytes                               ; continue to next digit
  done_number_of_bytes:
  mov edx, [link_pos]                                           ; edx is the pointer to the address part in the link
  mov dword[edx], 0                                             ; null pointer (has value 0) - this is the last link
  add dword[stack_pos], 4                                       ; pointer to next avilable cell
  handle_debug_mode
  jmp getinput


  push_number:
  check_overflow
  _malloc 1, 8                                                  ; insert the pointer of the new link to an empty cell.  size_t size - 4 byte for digit (with padding) and 4 for pointer to next link
  mov edx, dword[stack_pos]                                     ; edx = the address of the next free cell in stack
  mov [edx], eax                                                ; insert the address of the new link list to the cell in stack
  mov [link_pos], eax                                           ; link pos pointer to the new link
  inc dword[curr_stack_size]
  add dword[stack_pos], 4                                       ; pointer to next avilable cell
  getLen input , ecx                                            ; macro -> return value (length of string) to ecx
  dec ecx                                                       ; index to end = len -1
  convert_number:                                               ; return valur to eax, character to ecx
  movzx ebx, byte [input + ecx]                                 ; digit (0-7) should represent with up to 3 bits (less than byte = 8 bits)
  sub ebx, 48                                                   ; '0' == 48 in ASCII
  mov edx, [link_pos]                                           ; edx is the pointer to the digit part in the link
  mov dword[edx], ebx                                           ; copy the digit in binary to link
  add dword[link_pos], 4                                        ; pointer to address of next link
  dec ecx                                                       ; next digit
  cmp ecx, 0
  jl done_pushing  
  _malloc 1, 8                                                  ; new link in arg link list
  mov edx, [link_pos]                                           ; edx is the pointer to the pointer part in the link
  mov [edx], eax                                                ; saves pointer to next link
  mov dword[link_pos], eax
  jmp convert_number                                            ; continue to next digit
  done_pushing:
  mov edx, [link_pos]                                           ; edx is the pointer to the address part in the link
  mov dword[edx], 0                                             ; null pointer (has value 0) - this is the last link
  handle_debug_mode
  jmp getinput

  quit:                                                         ; free stack and quit
  cmp dword[curr_stack_size], 0
  jle done_free_all_list
  sub dword[stack_pos], 4                                       ; stack_pos points to the last cell in stack
  mov edx, [stack_pos]                                          ; edx is the pointer to the last cell in stack
  mov edx, [edx]                                                ; edx is the context of the last cell in stack (the address of the link)
  freelink edx
  dec dword[curr_stack_size]                                    ; curr_stack_size--
  jmp quit
  done_free_all_list:
  _free dword[head_of_stack]                                    ; free stack
  print_one_arg  dword [stdout], formatIntOCT , dword[action_counter]; prints number of operations

  done:
  popfd                                                         ; restore all EFLAGS
  mov esp, ebp			                                            ; free function activation frame
  pop ebp				                                                ; restore Base Pointer previous value (to returnt to the activation frame of main(...))
  ret				                                                    ; returns from assFunc(...) function
