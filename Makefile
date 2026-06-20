#!/usr/bin/env make -f

PREFIX=/usr
IDENTIFIER=net.alkalay.RDM

VERSION=2.3

CC=clang++
PACKAGE_BUILD=/usr/bin/pkgbuild
ARCH_FLAGS=-arch arm64
WARN_FLAGS=-Wall -Wextra
DEPLOYMENT_TARGET=-mmacosx-version-min=11.0
OBJC_FLAGS=-fobjc-arc $(WARN_FLAGS) $(DEPLOYMENT_TARGET)

.PHONY: build clean pkg dmg install

# Default target: build the .app bundle
build: RDM.app

RDM.app: SetResX Resources Info.plist monitor.icns
	mkdir -p RDM.app/Contents/MacOS/
	cp SetResX RDM.app/Contents/MacOS/
	cp -r Info.plist Resources RDM.app/Contents
	rm RDM.app/Contents/Resources/Icon_512x512.png
	rm RDM.app/Contents/Resources/StatusIcon_sel.png
	rm RDM.app/Contents/Resources/StatusIcon_sel@2x.png
	mv monitor.icns RDM.app/Contents/Resources


SetResX: main.o SRApplicationDelegate.o ResMenuItem.o cmdline.o utils.o
	$(CC) $^ -o $@ $(ARCH_FLAGS) $(DEPLOYMENT_TARGET) -framework Foundation -framework ApplicationServices -framework AppKit


clean:
	rm -f SetResX
	rm -f *.o
	rm -f *icns
	rm -rf RDM.app
	rm -rf pkgroot dmgroot
	rm -f *.pkg *.dmg

%.o: %.mm
	$(CC) $(OBJC_FLAGS) $(ARCH_FLAGS) $< -c -o $@


%.icns: %.png
	sips -s format icns $< --out $@

pkg: RDM.app
	mkdir -p pkgroot/Applications
	mv $< pkgroot/Applications/
	$(PACKAGE_BUILD) --root pkgroot/  --identifier $(IDENTIFIER) \
		--version $(VERSION) "RDM-$(VERSION).pkg"
	rm -f RDM.pkg
	ln -s RDM-$(VERSION).pkg RDM.pkg

dmg: pkg
	mkdir -p dmgroot
	cp RDM-$(VERSION).pkg dmgroot/
	rm -f RDM-$(VERSION).dmg
	hdiutil makehybrid -hfs -hfs-volume-name "RDM $(VERSION)" \
		-o "RDM-$(VERSION).dmg" dmgroot/
	rm -f RDM.dmg
	ln -s RDM-$(VERSION).dmg RDM.dmg
