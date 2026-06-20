#!/usr/bin/env make -f

PREFIX=/usr
IDENTIFIER=net.alkalay.RDM

VERSION=2.3

CC=clang++
ARCH_FLAGS=-arch arm64
WARN_FLAGS=-Wall -Wextra
DEPLOYMENT_TARGET=-mmacosx-version-min=11.0
OBJC_FLAGS=-fobjc-arc $(WARN_FLAGS) $(DEPLOYMENT_TARGET)

.PHONY: build clean dmg install

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
	rm -rf dmgroot
	rm -f *.pkg *.dmg

%.o: %.mm
	$(CC) $(OBJC_FLAGS) $(ARCH_FLAGS) $< -c -o $@


%.icns: %.png
	sips -s format icns $< --out $@

# Drag-and-drop DMG distribution: contains RDM.app plus a symlink to
# /Applications. User drags the app onto the Applications folder to install.
#
# We deliberately do NOT use pkgbuild/pkg here. pkgbuild emits AppleDouble
# (._*) metadata files into its Payload, which corrupts the installed bundle
# (files land with missing content). A plain .app inside a UDZO DMG is the
# standard way to distribute an unsigned macOS app and avoids that entirely.
dmg: RDM.app
	rm -rf dmgroot
	mkdir -p dmgroot
	cp -R RDM.app dmgroot/
	ln -s /Applications dmgroot/Applications
	rm -f RDM-$(VERSION).dmg
	hdiutil create -format UDZO -fs HFS+ -volname "RDM $(VERSION)" \
		-srcfolder dmgroot "RDM-$(VERSION).dmg"
	rm -f RDM.dmg
	ln -s RDM-$(VERSION).dmg RDM.dmg
