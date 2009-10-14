/*  $Id$

    Part of XPCE
    Designed and implemented by Anjo Anjewierden and Jan Wielemaker
    E-mail: jan@swi.psy.uva.nl

    Copyright (C) 1993-1997 University of Amsterdam. All rights reserved.
*/

#ifndef _PCE_FILE_H
#define _PCE_FILE_H

PceExternalClass(ClassFile);
class PceFile :public PceObject
{
public:
  PceFile() :
    PceObject(ClassFile)
  {
  }
  PceFile(PceArg path) :
    PceObject(ClassFile, path)
  {
  }
  PceFile(PceArg path, PceArg kind) :
    PceObject(ClassFile, path, kind)
  {
  }
};

inline PceFile
AsFile(PceArg a)
{ return *((PceFile*) &a);
}

#endif /*!_PCE_FILE_H*/
