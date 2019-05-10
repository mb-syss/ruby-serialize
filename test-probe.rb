#!/usr/bin/env ruby

require_relative 'prober'
require_relative 'gadgets'
require 'open3'

$jar = '/home/mbechler/work/eclipse-workspace/deser-test/target/deser-test-0.0.1-SNAPSHOT.jar'
$repo = '/home/mbechler/.m2/repository/'

def test_dummy_out(payl, reg, params)
  classpath = params['jars'].map { |x| $repo + x } + [$jar]
  args = ['java', '-cp', classpath.join(':'), 'Main']
  Open3.popen3(*args) do |sin, _sout, serr, proc|
    oos = Java::Serialize::ObjectOutputStream.new(sin, reg)
    oos.writeObject(payl)
    sin.close
    rv = proc.value
    if rv != 0
      err = serr.readlines
      #					puts err.to_s
      err.each do |line|
        einfo = line.split(' ', 3)
        return einfo[1] if einfo[0] == 'EX'
      end
    end
  end
end

$strategy = Java::Prober::ExceptionProbeStrategy.new(method(:test_dummy_out))
# strategy = Java::Prober::TimingProbeStrategy.new(method(:test_dummy_out))

def run_test(jars: [], expect: nil, expect_not: nil)
  reg = Java::Serialize::Registry.new
  reg.load('model/base-java9.json')
  ctx = Java::Prober::BuiltinProbes.new.create_context(reg, params: {
                                                         'jars'	=> 	jars
                                                       })
  $strategy.init(ctx)

  until ctx.probes.empty?
    probe = ctx.probes.shift
    begin
      $strategy.run(probe, ctx)
    rescue Exception => e
      puts e.backtrace.to_s
      puts '[E] ' + probe.to_s + ': ' + e.to_s
    end
  end

  puts ctx.gadgets.to_a.to_s

  gadgets = Java::Gadgets::BuiltinGadgets.new

  params = {
    'cmd' => '/bin/false',
    'classfiles' => [],
    'classpath' => 'http://localhost',
    'class' => 'Test',
    'jndiurl' => 'rmi://localhost/obj'
  }
  m = gadgets.find(ctx, params: params)

  gadget_ids = m.map(&:id)

  puts 'Matched gadgets: ' + gadget_ids.to_s

  if !expect.nil? && !gadget_ids.include?(expect)
    raise 'Expected match ' + expect
  end

  if !expect_not.nil? && gadget_ids.include?(expect_not)
    raise 'Expected no match ' + expect_not
  end

  m.each do |g|
    begin
      g.create(ctx, params: params)
    rescue Exception => e
      puts 'Failed to create ' + g.id + ':' + e.to_s
      puts e.backtrace.to_s
    end
  end
end

def mvn(group, art, ver)
  group.tr('.', '/') + '/' + art + '/' + ver + '/' + art + '-' + ver + '.jar'
end

tests = ['collections', 'beanutils', 'c3p0', 'groovy', 'jython', 'hibernate', 'spring', 'rome', 'hibernate-validator', 'hibernate', 'rhino', 'beanshell', 'jboss', 'vaadin']

tests = ARGV if ARGV.length >= 1

if tests.include?('collections')
  run_test(jars: [
             mvn('commons-collections', 'commons-collections', '3.2.1')
           ], expect: 'collections')

  run_test(jars: [
             mvn('commons-collections', 'commons-collections', '3.2.2')
           ], expect_not: 'collections')
end

if tests.include?('beanutils')
  run_test(jars: [
             mvn('commons-beanutils', 'commons-beanutils', '1.9.3')
           ], expect: 'beanutils')

  run_test(jars: [
             mvn('commons-beanutils', 'commons-beanutils', '1.8.3')
           ], expect: 'beanutils')

  run_test(jars: [
             mvn('commons-beanutils', 'commons-beanutils', '1.7.0')
           ], expect: 'beanutils')
end

if tests.include?('c3p0')
  run_test(jars: [
             mvn('com/mchange', 'mchange-commons-java', '0.2.11'),
             mvn('com.mchange', 'c3p0', '0.9.5.2')
           ], expect: 'c3p0')
  run_test(jars: [
             mvn('com/mchange', 'mchange-commons-java', '0.2.11'),
             mvn('c3p0', 'c3p0', '0.9.1.2')
           ], expect: 'c3p0')
end

if tests.include?('rome')
  run_test(jars: [
             mvn('rome', 'rome', '1.0')
           ], expect: 'rome')
  run_test(jars: [
             mvn('com.rometools', 'rome', '1.7.0')
           ], expect: 'rome')
end

if tests.include?('spring')
  run_test(jars: [
             mvn('javax.transaction', 'javax.transaction-api', '1.2'),
             mvn('org.springframework', 'spring-core', '4.3.7.RELEASE'),
             mvn('org.springframework', 'spring-beans', '4.3.7.RELEASE'),
             mvn('org.springframework', 'spring-tx', '4.3.7.RELEASE'),
             mvn('org.springframework', 'spring-context', '4.3.7.RELEASE')
           ], expect: 'spring-jta')
end

if tests.include?('groovy')
  run_test(jars: [
             mvn('org.codehaus.groovy', 'groovy', '2.3.9')
           ], expect: 'groovy')

  run_test(jars: [
             mvn('org.codehaus.groovy', 'groovy', '2.4.13')
           ], expect_not: 'groovy')
end

if tests.include?('jython')
  run_test(jars: [
             mvn('org.python', 'jython-standalone', '2.5.2')
           ], expect: 'jython')
end

if tests.include?('hibernate-validator')

  base = [mvn('commons-logging', 'commons-logging', '1.2'),
          mvn('org.jboss.logging', 'jboss-logging', '3.3.2.Final'),
          mvn('javax.annotation', 'javax.annotation-api', '1.2'),
          mvn('javax.validation', 'validation-api', '2.0.1.Final')]

  springproxy = [mvn('org.springframework', 'spring-core', '4.3.7.RELEASE'),
                 mvn('org.springframework', 'spring-aop', '4.3.7.RELEASE')]

  run_test(jars: base + springproxy + [
    mvn('org.hibernate', 'hibernate-validator', '5.3.6.Final')
  ], expect: 'hibernate-validator')

  run_test(jars: base + springproxy + [
    mvn('org.hibernate.validator', 'hibernate-validator', '6.0.9.Final')
  ], expect: 'hibernate-validator')
end

if tests.include?('hibernate')
  run_test(jars: [
             mvn('org.slf4j', 'slf4j-api', '1.7.25'),
             mvn('org.jboss.logging', 'jboss-logging', '3.3.2.Final'),
             mvn('org.dom4j', 'dom4j', '2.1.1'),
             mvn('javax.persistence', 'javax.persistence-api', '2.2'),
             mvn('javax.transaction', 'javax.transaction-api', '1.2'),
             mvn('org.hibernate', 'hibernate-core', '3.6.7.Final')
           ], expect: 'hibernate')

  run_test(jars: [
             mvn('org.slf4j', 'slf4j-api', '1.7.25'),
             mvn('org.jboss.logging', 'jboss-logging', '3.3.2.Final'),
             mvn('org.dom4j', 'dom4j', '2.1.1'),
             mvn('javax.persistence', 'javax.persistence-api', '2.2'),
             mvn('javax.transaction', 'javax.transaction-api', '1.2'),
             mvn('org.hibernate', 'hibernate-core', '4.3.11.Final')
           ], expect: 'hibernate')

  run_test(jars: [
             mvn('org.slf4j', 'slf4j-api', '1.7.25'),
             mvn('org.jboss.logging', 'jboss-logging', '3.3.2.Final'),
             mvn('javax.persistence', 'javax.persistence-api', '2.2'),
             mvn('javax.transaction', 'javax.transaction-api', '1.2'),
             mvn('org.hibernate', 'hibernate-core', '5.3.7.Final')
           ], expect: 'hibernate')

end

if tests.include?('rhino')
  run_test(jars: [
             mvn('rhino', 'js', '1.7R2')
           ], expect: 'rhino')
end

if tests.include?('beanshell')
  run_test(jars: [
             mvn('org.beanshell', 'bsh', '2.0b5')
           ], expect: 'beanshell')
end

if tests.include?('atomikos')
  run_test(jars: [
             mvn('com.atomikos', 'transactions-api', '3.9.3'),
             mvn('javax.transaction', 'javax.transaction-api', '1.2'),
             mvn('com.atomikos', 'atomikos-util', '3.9.3'),
             mvn('com.atomikos', 'transactions-jta', '3.9.3')
           ], expect: 'atomikos')

  run_test(jars: [
             mvn('com.atomikos', 'transactions-api', '4.0.6'),
             mvn('javax.transaction', 'javax.transaction-api', '1.2'),
             mvn('com.atomikos', 'atomikos-util', '4.0.6'),
             mvn('com.atomikos', 'transactions-jta', '4.0.6')
           ], expect: 'atomikos')
end

if tests.include?('jboss')
  run_test(jars: [
             mvn('org.slf4j', 'slf4j-api', '1.7.25'),
             mvn('javax.enterprise', 'cdi-api', '2.0'),
             mvn('javax.interceptor', 'javax.interceptor-api', '3.1'),
             mvn('javassist', 'javassist', '3.12.0.GA'),
             mvn('org.jboss.interceptor', 'jboss-interceptor-core', '2.0.0.Final'),
             mvn('org.jboss.interceptor', 'jboss-interceptor-spi', '2.0.0.Final')
           ], expect: 'jboss')

  run_test(jars: [
             mvn('org.slf4j', 'slf4j-api', '1.7.25'),
             mvn('javax.enterprise', 'cdi-api', '2.0'),
             mvn('javax.interceptor', 'javax.interceptor-api', '3.1'),
             mvn('javassist', 'javassist', '3.12.0.GA'),
             mvn('org.jboss.weld', 'weld-core', '1.1.33.Final')
           ], expect: 'jboss')
end

if tests.include?('vaadin')
  run_test(jars: [
             mvn('com.vaadin', 'vaadin-shared', '7.7.14'),
             mvn('com.vaadin', 'vaadin-server', '7.7.14')
           ], expect: 'vaadin')
end
