# Windows: cls
# Linux: clear
def run_spec
  system "cls && rspec spec/*.rb"
end
watch('.*\.rb') { run_spec }