# RPN-Calculator-assembly-
The program is a simple calculator for unlimited-precision unsigned integers written entirely in assembly language.

Reverse Polish notation (RPN) is a mathematical notation in which every operator follows all its operands, for example "3 + 4" would be presented as "3 4 +".For simplicity, each operator will appear on a separate line of input. Input and output operands are to be in octal representation.

The operations to be supported by the calculator are:
‘q’ – quit
‘+’ – unsigned addition
pop two operands from operand stack, and push the result, their sum
‘p’ – pop-and-print
pop one operand from the operand stack, and print its value to stdout
‘d’ – duplicate
push a copy of the top of the operand stack onto the top of the operand stack
‘&’ - bitwise AND, X&Y with X being the top of operand stack and Y the element next to x in the operand stack.
pop two operands from the operand stack, and push the result.
‘n’ – number of bytes the number is taking (note: same as half the hexadecimal digits rounded up)
pop one operand from the operand stack, and push one result.
‘*’ – unsigned multiplication (optional* - won't be checked)
pop two operands from operand stack, and push the result, their product. You are not allowed to implement x*y as x+x+x+…+x, y times.
