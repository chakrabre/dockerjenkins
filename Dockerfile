FROM centos:latest
MAINTAINER playniuniu <playniuniu@gmail.com>

ENV URL_JDK="http://download.oracle.com/otn-pub/java/jdk/8u112-b15/jdk-8u112-linux-x64.tar.gz" \
    URL_MAVEN="http://apache.fayea.com/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz" \
    URL_TOMCAT="http://apache.fayea.com/tomcat/tomcat-8/v8.5.6/bin/apache-tomcat-8.5.6.tar.gz" \
    URL_JENKINS="http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war" \
    URL_WEBLOGIC="http://blogcdn.uunus.cn/fmw_12.2.1.2.0_wls_quick_Disk1_1of1.zip" \
    FMW_JAR="fmw_12.2.1.2.0_wls_quick.jar"

ENV JAVA_HOME=/opt/jdk \
    JAVA=/opt/jdk/bin \
    M2_HOME=/opt/maven \
    M2=/opt/maven/bin \
    ORACLE_HOME=/opt/weblogic \
    CATALINA_HOME=/opt/tomcat \
    CATALINA_OPTS="-server -d64 -XX:+AggressiveOpts -Djava.awt.headless=true \
    -XX:MaxGCPauseMillis=500 -XX:MaxPermSize=256m -XX:PermSize=128m -Xmx512m -Xms128m -Xincgc" \
    JENKINS_HOME=/data/jenkins \
    PATH=${PATH}:/opt/jdk/bin:/opt/maven/bin:/opt/tomcat/bin \
    PREINSTALL_PACKAGES="git supervisor ansible openssh-clients openssh-server"

RUN yum install -y epel-release \
    && yum install -y $PREINSTALL_PACKAGES \
    && yum clean all

RUN mkdir /opt/downloads/ \
    && cd /opt/downloads/ \
    && echo "Download jdk" \
    && curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o jdk.tar.gz ${URL_JDK} \
    && echo "Download maven" \
    && curl -sSL -o maven.tar.gz ${URL_MAVEN} \
    && echo "Download tomcat" \
    && curl -sSL -o tomcat.tar.gz ${URL_TOMCAT} \
    && echo "Download jenkins" \
    && curl -sSL -o jenkins.war ${URL_JENKINS} \
    && echo "Download weblogic" \
    && curl -sSL -o weblogic.zip ${URL_WEBLOGIC}

COPY config/oraInst.loc /opt/downloads/
COPY config/ansible.cfg /etc/ansible/
COPY config/supervisord.conf /etc/
COPY config/entrypoint.sh /usr/bin/

RUN mkdir /opt/jdk \
    && mkdir /opt/maven \
    && mkdir /opt/tomcat \
    && mkdir /opt/weblogic \
    && tar xzf /opt/downloads/jdk.tar.gz -C /opt/jdk --strip-components=1 \
    && tar xzf /opt/downloads/maven.tar.gz -C /opt/maven --strip-components=1 \
    && tar xzf /opt/downloads/tomcat.tar.gz -C /opt/tomcat --strip-components=1 \
    && rm -rf /opt/tomcat/webapps/* \
    && mv /opt/downloads/jenkins.war /opt/tomcat/webapps/ROOT.war \
    && useradd oracle \
    && echo "oracle:oracle" | chpasswd \
    && chown oracle:oracle /opt/weblogic \
    && cd /opt/downloads/ \
    && $JAVA_HOME/bin/jar xf /opt/downloads/weblogic.zip \
    && su - oracle -c "$JAVA_HOME/bin/java -jar /opt/downloads/${FMW_JAR} -ignoreSysPrereqs -force -novalidation \
    -invPtrLoc /opt/downloads/oraInst.loc -jreLoc $JAVA_HOME ORACLE_HOME=${ORACLE_HOME}" \
    && rm -rf /opt/downloads/ \
    && chmod +x "/usr/bin/entrypoint.sh"

VOLUME /data
EXPOSE 22 8080 9001

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n"]
