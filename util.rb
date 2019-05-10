

$msf = false
begin
  require 'rex/ui/text/output/stdio'
  require 'msf/core/module'
  $console_printer = Rex::Ui::Text::Output::Stdio.new
  $msf = true
rescue LoadError
end

def msf?
  $msf
end

$debug = false

def debug(msg)
  return unless $debug
  if msf?
    $console_printer.print_line(msg)
  else
    puts msg
  end
end

def info(msg)
  if msf?
    $console_printer.print_status(msg)
  else
    puts '+ ' + msg
  end
end

def error(msg)
  if msf?
    $console_printer.print_error(msg)
  else
    puts 'ERROR: ' + msg
  end
end

def okay(msg)
  if msf?
    $console_printer.print_good(msg)
  else
    puts 'OKAY: ' + msg
  end
end

def vuln(msg)
  if msf?
    $console_printer.print_warning(msg)
  else
    puts 'FAIL: ' + msg
  end
end
