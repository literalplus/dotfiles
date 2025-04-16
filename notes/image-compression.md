# compress images

```bash
find . -name '*.JPG' | xargs -P8 -I{} magick "{}" -resize 75% -quality 80 "{}"  
```
