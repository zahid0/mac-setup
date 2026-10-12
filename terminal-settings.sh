defaults write com.apple.Terminal "Window Settings" -dict-add "Coding" '{
  name = Coding;
  CommandString = "tmux a || tmux";
  type = "Window Settings";
  shellExitAction = 1;
}'

defaults write com.apple.Terminal "Startup Window Settings" "Coding"
defaults write com.apple.Terminal "Default Window Settings" "Coding"
