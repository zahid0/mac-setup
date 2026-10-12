defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXRemoveOldTrashItems -bool true
defaults write com.apple.finder NewWindowTarget -string "PfHm"

killall Finder
