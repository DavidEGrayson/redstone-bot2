# Windows: cls
# Linux: clear
def run_spec
  #system "cls && rspec spec/*.rb"
  system "cls && rspec spec/nbt_spec.rb"
end
watch('.*\.rb') { run_spec }