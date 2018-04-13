// GCD

a = $1;
b = $2;

while (b != 0)
{
  t = b;
  b = a % b;
  a = t;
}

return a;
