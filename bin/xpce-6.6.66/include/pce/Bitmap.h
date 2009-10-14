/*  $Id$

    Part of XPCE
    Designed and implemented by Anjo Anjewierden and Jan Wielemaker
    E-mail: jan@swi.psy.uva.nl

    Copyright (C) 1993-1997 University of Amsterdam. All rights reserved.
*/

#ifndef _PCE_BITMAP_H
#define _PCE_BITMAP_H

PceExternalClass(ClassBitmap);
class PceBitmap :public PceObject
{
public:
  PceBitmap() :
    PceObject(ClassBitmap)
  {
  }
  PceBitmap(PceArg image) :
    PceObject(ClassBitmap, image)
  {
  }
  PceBitmap(PceArg image, PceArg transparent) :
    PceObject(ClassBitmap, image, transparent)
  {
  }
};

inline PceBitmap
AsBitmap(PceArg a)
{ return *((PceBitmap*) &a);
}

#endif /*!_PCE_BITMAP_H*/
