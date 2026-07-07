function Prompt {
    $Arrow =  [char]0xe0b0
    $Arrow2 = [char]0xe0b1

    $esc = "$([char]27)"
    $f = "$esc[38;2;"
    $b = "$esc[48;2;"
    $r = "$esc[0m"

    $c0 = "0m" # texte

    $c1 = "0;0;255m" # fond 1  bleu
    $c2 = "255;0;0m" # fond 2   rouge
    $c3 = "0;0;255m" # fleche 1
    $c4 = "255;0;0m" # fleche 2
    $c5 = "0;0;255m" # fleche 3

    $drive   = $PWD.Drive.Name
    $drive   = "$f$c0$b$c1{0}"    -f $($drive)
    $drive  += "$f$c3$b$c2{0}"    -f $($Arrow)
    
    $parent  = split-path $pwd -Parent | Split-Path -noQualifier
    $parent  = $parent -replace '^\\', ''
    $parent  = $parent -replace '\\', $Arrow2
    $parent  = "$f$c0$b$c2{0}"    -f $($parent)
    $parent += "$f$c4$b$c1{0}"    -f $($Arrow)
  
    $leaf    = split-path $pwd -Leaf
    $leaf    = "$f$c0$b$c1{0}"  -f $($leaf)
    $leaf   += "$r$f$c5{0}"         -f $($Arrow)

    "$drive$parent$leaf►$r "
}

set-alias pn pnpm