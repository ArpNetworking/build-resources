build-resources
===============

<a href="https://raw.githubusercontent.com/ArpNetworking/build-resources/master/LICENSE">
    <img src="https://img.shields.io/hexpm/l/plug.svg"
         alt="License: Apache 2">
</a>
<a href="https://travis-ci.com/ArpNetworking/build-resources">
    <img src="https://travis-ci.com/ArpNetworking/build-resources.svg?branch=master"
         alt="Travis Build">
</a>
<a href="http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22com.arpnetworking.build%22%20a%3A%22build-resources%22">
    <img src="https://img.shields.io/maven-central/v/com.arpnetworking.build/build-resources.svg"
         alt="Maven Artifact">
</a>

Resources for building Arp Networking projects.

Usage
-----

### Checkstyle

Determine the latest version of the build resources in [Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22com.arpnetworking.build%22%20a%3A%22build-resources%22).  If you have not, you should consider using the [Arp Networking Parent Pom](https://github.com/ArpNetworking/arpnetworking-parent-pom) instead of directly integrating with the build-resources package.

To integrate with the [Maven Checkstyle Plugin](https://maven.apache.org/plugins/maven-checkstyle-plugin/) declare a dependency on the build-resources package.  The __configLocation__ and __propertyExpansion__ must be set as shown below and the other settings can be customized as desired.

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-checkstyle-plugin</artifactId>
    <version>${maven.checkstyle.plugin.version}</version>
    <executions>
        <execution>
            <id>checkstyle-check</id>
            <phase>verify</phase>
            <goals>
                <goal>checkstyle</goal>
                <goal>checkstyle-aggregate</goal>
                <goal>check</goal>
            </goals>
            <configuration>
                <consoleOutput>true</consoleOutput>
                <logViolationsToConsole>true</logViolationsToConsole>
                <failOnViolation>true</failOnViolation>
                <maxAllowedViolations>0</maxAllowedViolations>
                <includeTestSourceDirectory>true</includeTestSourceDirectory>
                <configLocation>checkstyle.xml</configLocation>
                <propertyExpansion>
                     suppressions_file=${project.build.directory}/checkstyle-suppressions.xml
                     header_file=${project.build.directory}/al2
                </propertyExpansion>
            </configuration>
        </execution>
    </executions>
   <dependencies>
       <dependency>
           <groupId>com.arpnetworking.build</groupId>
           <artifactId>build-resources</artifactId>
           <version>VERSION</version>
       </dependency>
   </dependencies>
</plugin>
```

&copy; Arp Networking, 2015
