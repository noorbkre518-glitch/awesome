import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MessagingService } from './messaging.service';
import { MessagingController } from './messaging.controller';

@Module({
  imports: [AuthModule],
  controllers: [MessagingController],
  providers: [MessagingService],
})
export class MessagingModule {}
