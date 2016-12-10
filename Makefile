make := $(lastword $(MAKEFILE_LIST))
$(make):;
SHELL := bash
.DEFAULT_GOAL := main

encode = $(shell echo -n $1 | jq -s -R -r @uri)

self := automysqlbackup
site := https://sourceforge.net
path = projects/$(self)/files/AutoMySQLBackup/$(call encode, 'AutoMySQLBackup VER $1')

last.v := 3.0
last.r := rc6
last.b := $(self)-v$(last.v)_$(last.r)
last.f := $(last.b).tar.gz
last.u := $(site)/$(call path,$(last.v))/$(last.f)
$(last.f) := $(last.u)

jessie.v := 2.5
jessie.f := $(self).sh.$(jessie.v)
jessie.u := $(site)/$(call path,$(jessie.v))/$(jessie.f)
$(jessie.f) := $(jessie.u)

last25.v := 2.5
last25.r := 1-01
last25.f := $(self)-$(last25.v).$(last25.r).sh
last25.u := $(site)/$(call path,$(last25.v))/$(last25.f)
$(last25.f) := $(last25.u)

$(last.f) $(jessie.f) $(last25.f):; wget -S $($@)
$(last.b)/$(self): $(last.f); mkdir -p $(@D); (cd $(@D); tar zxvf ../$<); touch $@ -r $<

####

adam := .adam
$(adam):; touch -d '1970-01-01 01' $@

ultimo := /proc/self
$(ultimo):;

old-or-young := && echo $(adam) || echo $(ultimo)

####

.gitignore: $(make); echo -e '*~\n$(last.f)\n$(adam)\n$(create.stone)' > $@

main := $(last.b)/$(self) $(jessie.f) $(last25.f) .gitignore
main += create init conf remote
main: $(main)
.PHONY: main check create init conf remote

github := https://api.github.com
user   := thydel
repo   := $(self)-copy

check = curl -s $(github)/repos/$(user)/$1 | jq -e .name
check/%:; $(call check,$*)
check: check/$(repo)

create  = source <(< ~/.gpg-agent-info xargs -i echo export {});
create += p=$$(pass github/$(user));
create += curl -s -u $(user):$$p $(github)/user/repos -d '{ "name": "'$1'" }';

create.stone := .created
create.dep := $(shell $(call check,$(repo)) > /dev/null $(old-or-young))
$(create.stone): $(create.dep); $(call create, $(repo)); touch $@
create: $(create.stone)
create/%:; $(call check,$*) > /dev/null || $(call create,$*)

.git:; git init
init: .git

email := t.delamare@epiconcept.fr

config  = git config push.default simple;
config += git config user.email;

config.dep := $(shell grep -q $(email) .git/config $(old-or-young))
.git/config:: $(config.dep); $($(@F))
conf: .git/config

remote.url = git@$(user).github.com:$(user)/$(repo).git
remote.cmd = git remote add $(user) $(remote.url)
remote.dep = $(shell grep -q "$(remote.url)" .git/config $(old-or-young))
.git/config:: $(remote.dep); $(remote.cmd)
remote: .git/config
