/*
 * Copyright (C) 2015-2018 Anton Burdinuk
 * clark15b@gmail.com
 * http://xupnpd.org
 */

#include "compat.h"

#if defined(__APPLE__) || defined(__MIPSEL__)
#include <fcntl.h>

int pipe2(int* fd,int flags)
{
    int rc=pipe(fd);

    if(rc)
        return rc;

    fcntl(fd[0],F_SETFL,flags);

    fcntl(fd[1],F_SETFL,flags);

    return 0;
}

#endif /* __APPLE__ */
