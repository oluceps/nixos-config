#!/usr/bin/env fish
for file in (find . -maxdepth 1 -type f -name '*age')
    rage -d -i ~/.ssh/age/priv.age $file
    # rage -d -i ./age-ybk-7d5d.pub $file
end
