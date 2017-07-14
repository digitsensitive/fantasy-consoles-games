# cls
[Official API](https://github.com/nesbox/tic.computer/wiki/cls)


## Javascript

Example limited to the colors from [0-15].
If you use another number (not limit), you will see a special fill pattern.

```
// cls demo

var c = 0;

function TIC() {

  // Use Up/Down to change color
  if (btnp(0) & c < 16) { c = c + 1; }
  if (btnp(1) & c > -1) { c = c - 1; }

  // Clear with the color
  cls(c);

  // Make a background for the text
  rect(0, 0, 240, 8, 0);

  // Ouput a text with function call
  print("cls("+c+")  --Use Up/Down to change color");

}
```

## TypeScript
```
Coming soon.
```
